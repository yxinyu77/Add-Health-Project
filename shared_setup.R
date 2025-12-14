# # =========================
# Shared setup + data prep  (UPDATED to match essay)
# =========================
library(dplyr)
library(readr)
library(ggplot2)
library(splines)
library(broom)

pick_col <- function(df, candidates, label = "variable") {
  hit <- intersect(candidates, names(df))
  if (length(hit) == 0) {
    stop(sprintf("Cannot find required %s. Tried: %s", label, paste(candidates, collapse = ", ")))
  }
  hit[[1]]
}

# Treat common Add Health special codes as missing (covers 6/8 refusals, 96/98/99/999, etc.)
to_na <- function(x) {
  x <- as.numeric(x)
  dplyr::na_if(x, 6)  |>
    (\(v) dplyr::na_if(v, 8))()  |>
    (\(v) dplyr::na_if(v, 96))() |>
    (\(v) dplyr::na_if(v, 97))() |>
    (\(v) dplyr::na_if(v, 98))() |>
    (\(v) dplyr::na_if(v, 99))() |>
    (\(v) dplyr::na_if(v, 996))()|>
    (\(v) dplyr::na_if(v, 997))()|>
    (\(v) dplyr::na_if(v, 998))()|>
    (\(v) dplyr::na_if(v, 999))()
}

recode_mvpa_midpoint <- function(x) {
  # Add Health H1DA4/H1DA5/H1DA6 codes: 0,1,2,3 plus missing codes (6=refused, 8=DK, etc.)
  # Midpoints per your paper: 0, 1.5, 3.5, 5
  x <- to_na(x)
  dplyr::case_when(
    x == 0 ~ 0,
    x == 1 ~ 1.5,
    x == 2 ~ 3.5,
    x == 3 ~ 5,
    TRUE ~ NA_real_
  )
}

make_analysis_dataset <- function(path_w1 = "wave1.csv", path_w4 = "wave4.csv") {
  
  w1 <- readr::read_csv(path_w1, show_col_types = FALSE)
  w4 <- readr::read_csv(path_w4, show_col_types = FALSE)
  
  id_w1 <- pick_col(w1, c("AID"), "Wave I ID (AID)")
  id_w4 <- pick_col(w4, c("AID"), "Wave IV ID (AID)")
  
  # ----- Wave I: exposure + baseline covariates -----
  h1da4 <- pick_col(w1, c("H1DA4"), "H1DA4")
  h1da5 <- pick_col(w1, c("H1DA5"), "H1DA5")
  h1da6 <- pick_col(w1, c("H1DA6"), "H1DA6")
  
  sex1  <- pick_col(w1, c("BIO_SEX"), "Wave I sex (BIO_SEX)")
  byr   <- pick_col(w1, c("H1GI1Y"), "Birth year (H1GI1Y)")
  iyear <- pick_col(w1, c("IYEAR"), "Interview year (IYEAR)")
  
  race  <- pick_col(w1, c("H1GI9"), "Race (H1GI9)")
  hisp  <- pick_col(w1, c("H1GI4"), "Hispanic indicator (H1GI4)")
  
  inc   <- pick_col(w1, c("PA55"), "Household income (PA55)")
  pedu  <- pick_col(w1, c("PA12"), "Parent education (PA12)")
  
  # Baseline BMI from self-reported height/weight at Wave I:
  # H1GH59A = feet, H1GH59B = inches, H1GH60 = weight (lbs)
  ht_ft <- pick_col(w1, c("H1GH59A"), "Height feet (H1GH59A)")
  ht_in <- pick_col(w1, c("H1GH59B"), "Height inches (H1GH59B)")
  wt_lb <- pick_col(w1, c("H1GH60"),  "Weight lbs (H1GH60)")
  
  w1_small <- w1 %>%
    transmute(
      AID = .data[[id_w1]],
      
      mvpa = recode_mvpa_midpoint(.data[[h1da4]]) +
        recode_mvpa_midpoint(.data[[h1da5]]) +
        recode_mvpa_midpoint(.data[[h1da6]]),
      
      # sex (Wave I)
      female_w1 = case_when(
        to_na(.data[[sex1]]) == 2 ~ 1L,
        to_na(.data[[sex1]]) == 1 ~ 0L,
        TRUE ~ NA_integer_
      ),
      
      # age at Wave I (approx)
      age_w1 = {
        iy <- to_na(.data[[iyear]])
        by <- to_na(.data[[byr]])
        ifelse(!is.na(iy) & !is.na(by), iy - by, NA_real_)
      },
      
      # race/ethnicity (simple, defensible categories)
      hispanic = case_when(
        to_na(.data[[hisp]]) == 1 ~ 1L,
        to_na(.data[[hisp]]) == 0 ~ 0L,
        TRUE ~ NA_integer_
      ),
      race_w1 = to_na(.data[[race]]),
      
      race_eth = case_when(
        hispanic == 1L ~ "Hispanic",
        race_w1 == 1 ~ "White",
        race_w1 == 2 ~ "Black",
        race_w1 == 3 ~ "Native American",
        race_w1 == 4 ~ "Asian/Pacific Islander",
        race_w1 == 5 ~ "Other",
        TRUE ~ NA_character_
      ),
      
      income_w1 = to_na(.data[[inc]]),
      parent_educ_w1 = to_na(.data[[pedu]]),
      
      # baseline BMI (lbs/in^2 * 703)
      bmi_w1 = {
        ft <- to_na(.data[[ht_ft]])
        inch <- to_na(.data[[ht_in]])
        wt <- to_na(.data[[wt_lb]])
        
        h_in <- ifelse(!is.na(ft) & !is.na(inch), 12 * ft + inch, NA_real_)
        ifelse(!is.na(wt) & !is.na(h_in) & h_in > 0,
               703 * wt / (h_in^2),
               NA_real_)
      }
    ) %>%
    mutate(
      race_eth = factor(race_eth,
                        levels = c("White", "Black", "Hispanic",
                                   "Asian/Pacific Islander", "Native American", "Other"))
    )
  
  # ----- Wave IV: outcome + measured anthropometrics -----
  sex4 <- pick_col(w4, c("BIO_SEX4"), "Wave IV sex (BIO_SEX4)")
  h4bmi <- pick_col(w4, c("H4BMI"), "H4BMI")
  h4hgt <- pick_col(w4, c("H4HGT"), "H4HGT (measured height)")
  h4wgt <- pick_col(w4, c("H4WGT"), "H4WGT (measured weight)")
  
  w4_small <- w4 %>%
    transmute(
      AID = .data[[id_w4]],
      
      # prefer H4BMI when present; else compute from H4HGT/H4WGT assuming cm/kg
      bmi4_raw = to_na(.data[[h4bmi]]),
      hgt_cm = to_na(.data[[h4hgt]]),
      wgt_kg = to_na(.data[[h4wgt]]),
      
      bmi = ifelse(!is.na(bmi4_raw),
                   bmi4_raw,
                   ifelse(!is.na(hgt_cm) & !is.na(wgt_kg) & hgt_cm > 0,
                          wgt_kg / ( (hgt_cm / 100)^2 ),
                          NA_real_)),
      
      female_w4 = case_when(
        to_na(.data[[sex4]]) == 2 ~ 1L,
        to_na(.data[[sex4]]) == 1 ~ 0L,
        TRUE ~ NA_integer_
      )
    ) %>%
    mutate(
      # Filter implausible BMI values (your essay claims you do this)
      bmi = ifelse(!is.na(bmi) & (bmi < 15 | bmi > 60), NA_real_, bmi),
      obese = as.integer(!is.na(bmi) & bmi >= 30)
    )
  
  # ----- Merge + minimal required filtering -----
  dat <- inner_join(w1_small, w4_small, by = "AID") %>%
    mutate(
      # coalesce sex from Wave IV first, fallback to Wave I
      female = coalesce(female_w4, female_w1)
    ) %>%
    filter(!is.na(mvpa), !is.na(bmi), !is.na(obese), !is.na(female)) %>%
    transmute(
      AID,
      mvpa,
      bmi,
      obese,
      female,
      age_w1,
      race_eth,
      income_w1,
      parent_educ_w1,
      bmi_w1
    )
  
  dat
}

# Descriptive plots for your Data section
make_figures <- function(dat, out_dir = ".") {
  
  dat <- dat %>%
    mutate(
      mvpa_cat = cut(
        mvpa,
        breaks = c(-Inf, 0, 4, 9, Inf),
        labels = c("0", "1--4", "5--9", "$\\geq 10$"),
        right = TRUE
      )
    )
  
  p1 <- ggplot(dat, aes(x = mvpa)) +
    geom_histogram(bins = 30) +
    labs(x = "Weekly MVPA bouts (midpoint composite)", y = "Count")
  
  ggsave(file.path(out_dir, "mvpahistogram.png"), p1, width = 7, height = 4, dpi = 300)
  
  p2_dat <- dat %>%
    group_by(mvpa_cat) %>%
    summarise(prev_obese = mean(obese), n = n(), .groups = "drop")
  
  p2 <- ggplot(p2_dat, aes(x = mvpa_cat, y = prev_obese)) +
    geom_col() +
    labs(x = "Adolescent MVPA category", y = "Obesity prevalence (Wave IV)")
  
  ggsave(file.path(out_dir, "obesitybymvpa.png"), p2, width = 7, height = 4, dpi = 300)
  
  invisible(list(p1 = p1, p2 = p2, p2_dat = p2_dat))
}
