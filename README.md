# Census Population Targets

This repository contains two files that collect counts of the resident population of the United States from the U.S. Census Bureau's [Population Estimates Program (PEP)](https://www.census.gov/programs-surveys/popest/about.html) for years 1900 to 2024. These counts are useful for survey weight adjustment &mdash; as targets for post-stratification, raking (iterative proportional fitting), or calibration &mdash; or for denominators in prevalence estimates. 

## Quick Start

1. Pick a file, download it, and load in the statistical programming language of your choice.
2. Pick a race categorization scheme and filter by the scheme.
3. Group by whatever variables you want to use to define your count cells and sum the rows.
4. Pivot the table long to wide, if needed.

### Picking a File

The two files are

- `output/census_targets_by_age.csv`
- `output/census_targets_adults_by_age.csv`

The PEP age groups have a group for 15 to 19 years of age. For raking surveys of adults, this group needs to be broken down into a group for 18 to 19 years of age, which is why the second `output/census_targets_adults_by_age.csv` file exists.

If you want only counts of adults, use `output/census_targets_adults_by_age.csv`. Otherwise, use `output/census_targets_by_age.csv`.

### Picking a Race Categorization Scheme

The PEP has changed the way it classified race three times so far. Therefore, there are four different ways we can classify race when using the data. However, only one scheme is available for all years in the data set. The below table summarizes what race schemes are available for what years.

| Scheme | Values | Years available |
|---|---|---|
| `race2` | White, Nonwhite | 1900-2024 |
| `race3` | White, Black, Other | 1960-2024 |
| `race4` | White, Black, AIAN, API | 1980-1999 |
| `race6` | White, Black, AIAN, Asian, NHPI, TwoOrMore | 2000-2024 |

Once you pick the scheme you want to use, you should filter the data to include only the rows where the `RaceScheme` variable equals your chosen scheme name.

### Grouping by Desired Variables and Summing Counts

After filtering for `RaceScheme`, you will need to sum up the remaining rows based on whatever variables you want to use to define your counts, such as `Sex`, `Race`, or `AgeGroup`. You will also need to group by and sum based on `Year`.

Note that `HispanicOrigin` is available only from 1980 on.

If you want to just get a total count of the entire population, then group by just `Year` and sum.

### Pivoting the Table Wide (Optional)

The data are distributed in long-table format, which is one row per count. If you want to work with data that are in wide-table format, which is one row per year with a separate column for each count, then pivot the data after doing the filtering on race categorization scheme and summing of rows for the previous two steps.

### Example Programs

Below are examples of how to prepare the data to get target counts for the General Social Survey, which has a target population of adults residing in the United States and has been administered since 1972.

#### R

```r
library(readr)
library(dplyr)
library(tidyr)

targets <- read_csv("census_targets_adults_by_age.csv") |>
  filter(RaceScheme == "race3", Year >= 1972, Year <= 2024) |>
  group_by(Year, Race, Sex, AgeGroup) |>
  summarize(Population = sum(Population), .groups = "drop")

# --- optional: pivot from long to wide, one row per Year ---
targets_wide <- targets |>
  unite(Cell, Race, Sex, AgeGroup) |>
  pivot_wider(names_from = Cell, values_from = Population)
```

#### SAS

```sas
proc import datafile="census_targets_adults_by_age.csv"
    out=targets_raw dbms=csv replace;
    getnames=yes;
run;

data targets_filtered;
    set targets_raw;
    where RaceScheme = "race3" and 1972 <= Year <= 2024;
run;

proc summary data=targets_filtered nway;
    class Year Race Sex AgeGroup;
    var Population;
    output out=targets(drop=_type_ _freq_) sum=Population;
run;

/* --- optional: pivot from long to wide, one row per Year --- */
data targets_long;
    set targets;
    length Cell $40;
    Cell = catx('_', Race, Sex, AgeGroup);
run;

proc sort data=targets_long;
    by Year;
run;

proc transpose data=targets_long out=targets_wide(drop=_name_) prefix=Pop_;
    by Year;
    id Cell;
    var Population;
run;
```

#### Stata

```stata
import delimited "census_targets_adults_by_age.csv", clear

keep if racescheme == "race3" & year >= 1972 & year <= 2024

collapse (sum) population, by(year race sex agegroup)

* --- optional: pivot from long to wide, one row per year ---
egen cell = concat(race sex agegroup), punct("_")
drop race sex agegroup

reshape wide population, i(year) j(cell) string
```

#### SPSS

```spss
GET DATA /TYPE=TXT
  /FILE="census_targets_adults_by_age.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /VARIABLES=Year F4.0 RaceScheme A10 Race A20 Sex A6 AgeGroup A20
             HispanicOrigin A11 Population F12.0.

SELECT IF (RaceScheme = "race3" AND Year >= 1972 AND Year <= 2024).

AGGREGATE
  /OUTFILE=* MODE=REPLACE
  /BREAK=Year Race Sex AgeGroup
  /Population=SUM(Population).

* --- optional: pivot from long to wide, one row per Year ---
STRING Cell (A40).
COMPUTE Cell = CONCAT(RTRIM(Race), "_", RTRIM(Sex), "_", RTRIM(AgeGroup)).

CASESTOVARS
  /ID=Year
  /INDEX=Cell
  /GROUPBY=VARIABLE.
```

#### Python

```python
import pandas as pd

targets = pd.read_csv("census_targets_adults_by_age.csv")
targets = targets[
    (targets["RaceScheme"] == "race3")
    & (targets["Year"] >= 1972)
    & (targets["Year"] <= 2024)
]
targets = (
    targets.groupby(["Year", "Race", "Sex", "AgeGroup"], as_index=False)["Population"]
    .sum()
)

# --- optional: pivot from long to wide, one row per Year ---
targets_wide = targets.copy()
targets_wide["Cell"] = (
    targets_wide["Race"] + "_" + targets_wide["Sex"] + "_" + targets_wide["AgeGroup"]
)
targets_wide = targets_wide.pivot(index="Year", columns="Cell", values="Population").reset_index()
```

### Example Results

The tables below show excerpts of real output from the example programs.

#### Long-Table Format

10 contiguous rows from `targets`, starting at the first row (1972, Black, Female):

| Year | Race | Sex | AgeGroup | Population |
| --- | --- | --- | --- | --- |
| 1972 | Black | Female | 18 to 19 years | 501438 |
| 1972 | Black | Female | 20 to 24 | 1098913 |
| 1972 | Black | Female | 25 to 29 | 835606 |
| 1972 | Black | Female | 30 to 34 | 738633 |
| 1972 | Black | Female | 35 to 39 | 665486 |
| 1972 | Black | Female | 40 to 44 | 649360 |
| 1972 | Black | Female | 45 to 49 | 615446 |
| 1972 | Black | Female | 50 to 54 | 569676 |
| 1972 | Black | Female | 55 to 59 | 463555 |
| 1972 | Black | Female | 60 to 64 | 440945 |

#### Wide-Table Format

5 contiguous rows from `targets_wide`, one row per `Year`. `targets_wide` has 91 columns in total (`Year` plus one `Population` column per Race_Sex_AgeGroup combination); only the first 5 of those columns are shown here for readability:

| Year | Black_Female_18 to 19 years | Black_Female_20 to 24 | Black_Female_25 to 29 | Black_Female_30 to 34 | Black_Female_35 to 39 |
| --- | --- | --- | --- | --- | --- |
| 1972 | 501438 | 1098913 | 835606 | 738633 | 665486 |
| 1973 | 525805 | 1141902 | 876126 | 767294 | 669316 |
| 1974 | 545142 | 1185957 | 931372 | 793238 | 676714 |
| 1975 | 565649 | 1233546 | 988450 | 819735 | 687144 |
| 1976 | 579151 | 1275037 | 1064461 | 832203 | 706288 |

## Variables

The contents of the output files are summarized below. In the long-table format in which the files are distributed, each row has a `Population` column that is the count for that cell, and the other variables define the cell.

| Variable | Value | Description | Years available |
|---|---|---|---|
| `Year` | — | July 1 reference year of the estimate | 1900-2024 |
| `Sex` | Male | | 1900-2024 |
| | Female | | 1900-2024 |
| `AgeGroup` | Under 5, 5 to 9, ..., 80 to 84 | 5-year bins | 1900-2024 |
| | 85 years and over | | 1940-2024 |
| | 75 years and over | catch-all in place of the 75-79/80-84/85+ split | 1900-1939 |
| | 15 to 19 | | 1900-2024 (all-ages file only) |
| | 18 to 19 years | in place of "15 to 19" | 1900-2024 (adults file only) |
| `Population` | — | estimated civilian resident population of the cell | 1900-2024 |
| `RaceScheme` | race2 | 2-category scheme | 1900-2024 |
| | race3 | 3-category scheme | 1960-2024 |
| | race4 | 4-category scheme | 1980-1999 |
| | race6 | 6-category scheme | 2000-2024 |
| `Race` | White | | 1900-2024 |
| | Nonwhite | `race2`'s residual; no internal breakdown | 1900-2024 |
| | Black | | 1960-2024 |
| | Other | `race3`'s residual; not the same population as `Nonwhite` | 1960-2024 |
| | AIAN | American Indian and Alaska Native | 1980-2024 |
| | API | Asian and Pacific Islander, `race4`'s combined category | 1980-1999 |
| | Asian | | 2000-2024 |
| | NHPI | Native Hawaiian and Pacific Islander, split out of `API` | 2000-2024 |
| | TwoOrMore | Two or More Races | 2000-2024 |
| `HispanicOrigin` | NA | no Hispanic-origin data exists in the source for that year | 1900-1979 |
| | Hispanic | | 1980-2024 |
| | NonHispanic | | 1980-2024 |

## Why You Shouldn't Be Using American Community Survey (ACS) for This

Many tutorials on survey weight adjustment &mdash; called "post-stratification" (if uni-dimensional), "raking" (if multi-dimensional), "calibration" (if model-based), "iterative proportional fitting" (for a more general concept in mathematics) &mdash;  suggest using Census's American Community Survey (ACS) to get target counts for the raking. However, this is entirely the wrong approach.

Despite being the wrong approach, using the ACS for census targets is common advice. Here is a short list of tutorials that suggest using the ACS for survey weight adjustment targets:

- [How different weighting methods work (Pew Research Center)](https://www.pewresearch.org/methods/2018/01/26/how-different-weighting-methods-work/)
- [Weighting survey data with the pewmethods R package (Pew Research Center)](https://www.pewresearch.org/decoded/2020/03/26/weighting-survey-data-with-the-pewmethods-r-package/)
- [`anesrake` CRAN documentation](https://cran.r-project.org/web/packages/anesrake/anesrake.pdf)
- [Survey Raking: An Illustration (R-bloggers)](https://www.r-bloggers.com/2018/12/survey-raking-an-illustration/)
- [Calibrating survey data using iterative proportional fitting (`ipfraking`, Boston College RePEc)](http://fmwww.bc.edu/RePEc/bocode/i/ipfraking-v32.pdf)
- [Rake Weighting: How to Weight Survey Data with Multiple Variables (MeasuringU)](https://measuringu.com/rake-weighting-how-to-weight-survey-data-with-multiple-variables/)
- [Survey Weighting in R: Using Rake Weights to Adjust Samples to Population Demographics (RStudio Pubs)](https://rstudio-pubs-static.s3.amazonaws.com/1244160_2e818bffbd0a44fda1fa450edc8199d2.html)
- [Weighting Data in R (Medium, "Survey Skills in R")](https://medium.com/@coraghenry/survey-skills-in-r-6c99e31a05e7)

There are three main issues with the use of the ACS for targets. They all stem from the fact that the ACS is itself a survey, and we should be using census counts for targets, not estimates from another survey.

1. **The ACS itself uses the PEP for weight adjustment targets.** It is true that if you stick to just the variables on the PEP, that the targets you get from the ACS will be basically the same. What people are doing when using the ACS for raking targets is using the ACS as a convenience instrument to access PEP counts. Why? Because the ACS itself uses PEP counts for its own weight adjustments. That is what is referred to as "ratio estimation" by age, sex, race, and Hispanic origin in the [ACS documentation](https://www.census.gov/content/dam/Census/library/publications/2010/acs/Chapter_11_RevisedDec2010.pdf). Thus, the ACS is acting like a middleman to the PEP counts. However, when you start using other variables other than the ones used to define cells in the PEP, then you really get into trouble.
2. **The ACS has sampling error, and it can be quite large.** Because the ACS is itself a survey, it comes with its own sampling error. If you are adjusting a different survey's weights based on ACS estimates, you are incorporating the sampling error for the ACS estimates into the estimates you are calculating from the other survey, whether you acknowledge it or not. However, no one is actually increasing the reported survey error of their own estimates because of this. The ACS sampling error can be nontrivial, for instance, [its own documentation](https://www.census.gov/content/dam/Census/library/publications/2020/acs/acs_general_handbook_2020_ch07.pdf) reports that in the 2007-2011 ACS, 72.8% of census tracts had a margin of error _larger_ than the estimate itself for children under 5 in poverty.
3. **The ACS intentionally obfuscates small-cell counts for disclosure avoidance.** The ACS will intentionally make the counts for small cells less accurate in order to [decrease the risk](https://www2.census.gov/programs-surveys/acs/tech_docs/pums/accuracy/2017_2021AccuracyPUMS.pdf) that a specific survey respondent is identified. This compounds with the issue of relatively large sampling error for small cells.

Using the ACS and accessing its large set of variables allows the data user to create cells whose counts are statistically indistinguishable from zero, and then to adjust another survey's weights based on these nonsense figures. Since using the ACS instead of the PEP directly is just using the ACS as a proxy for the PEP, we should just use the PEP directly.

I suspect so many people are using the ACS instead of the PEP directly because it is easier to access the ACS. With this project, though, we can now easily use the PEP itself.


## How the Output Files Were Built

The file `census_targets.Rmd` in this repo is the canonical definition of what data were pulled and how the data were processed in order to create the two output files. 

The work to collect these counts started in another, private Git repository where I do my statistical analysis work. I decided to extract the work and make it generic enough to be reused.

`census_targets.Rmd` itself was written by Claude Code at my direction, based on previous code I had written the first time I needed PEP counts for survey weight adjustment. I then proofread the code in `census_targets.Rmd` to make sure there were no errors in the calculations. If anyone finds any issues in the way these counts are calculated, please bring them to my attention by opening a GitHub issue.

### Data Sources and Documentation

The table below summarizes all the different data inputs that were used as inputs.
 
| Years | Source | Files Used | Documentation |
|---|---|---|---|
| 1900-1979 | Census, [National Intercensal Tables: 1900-1990](https://www.census.gov/data/tables/time-series/demo/popest/pre-1980-national.html) | `pe-11-1900s.xls` through `pe-11-1970s.xls`, one decade-bundle workbook per decade | — |
| 1980-1989 | Census, [National Intercensal Datasets: 1980-1990](https://www.census.gov/data/datasets/time-series/demo/popest/1980s-national.html) | 10 quarterly `E{yy}{yy+1}RQI.TXT` files (distributed as zips), one per year-pair | [1980-1990 national file-layout documentation](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/1980-1990/nat-detail-layout.txt) |
| 1990-1999 | Census, [1990-2000 intercensal county file directory](https://www2.census.gov/programs-surveys/popest/tables/1990-2000/intercensal/st-co/) | 10 `stch-icen{year}.txt` flat files, one per year | [1990-2000 intercensal file-layout documentation](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/1990-2000/stch-intercensal_layout.txt) and [Population Estimates Categorical Variables, 1990-2000](https://www.census.gov/data/developers/data-sets/popest-popproj/popest/popest-vars/1990-2000.html) |
| 2000-2009 | `censusapi` dataset [`pep/int_charagegroups`, vintage 2000](https://www.census.gov/data/developers/data-sets/popest-popproj/popest/2000-2010.html) | — | [`pep/int_charagegroups` variables page](https://api.census.gov/data/2000/pep/int_charagegroups/variables.html) |
| 2010-2019 | Census, [National Intercensal Population by Characteristics: 2010-2020](https://www.census.gov/data/datasets/time-series/demo/popest/intercensal-2010-2020-national-detail.html) | `nc-est2020int-asr6h.xlsx` | [Methodology, Limitations and Applications of the 2010-2020 Intercensal Population and Housing Unit Estimates](https://www.census.gov/newsroom/blogs/research-matters/2024/11/2010-2020-intercensal-population-and-housing-unit-estimates.html) |
| 2020-2024 | Census, [National Population by Characteristics: 2020-2025](https://www.census.gov/data/datasets/time-series/demo/popest/2020s-national-detail.html) | `nc-est2024-alldata-c-file{02,04,06,08,10}.csv`, from the [Vintage 2024 datasets directory](https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/national/asrh/) | [`NC-EST2024-ALLDATA` file-layout documentation](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/2020-2024/NC-EST2024-ALLDATA.pdf) |

The PEP releases two kinds of population estimates: postcensal and intercensal. The complete enumeration of the U.S. population occurs just once per decade. For nine years in between a decennial census, the PEP creates estimates by calculating changes to the decennial census count with vital statistics (births and deaths) and migration statistics. The postcensal estimates extrapolate off of the most recent decennial census that preceded the year of the estimates. The intercensal estimates interpolate between both the preceding decennial census and the following decennial census.

Generally, intercensal estimates are more accurate. As can be seen in the above table, intercensal estimates were used for most years in this data set. However, since the 2030 census has not happened yet, postcensal estimates are used for the 2020-2024 years.

## Issues with the PEP Data

### Discontinuities

If you are using PEP counts from both before and after a point where there is a discontinuity in the underlying data, you will have to account for it. The table below summarizes where the discontinuities occur.

| Break | What changes |
| --- | --- |
| 1939/1940 | In 1939 and before, the open-ended top age bin is "75 years and over." From 1940 and thereafter, the top age bin is "85 years and over." |
| 1949/1950 | In 1949 and before, the residents of Alaska and Hawaii are not included in the counts. From 1950 and thereafter, Alaska and Hawaii are included. |
| 1959/1960 | The race scheme changes from two categories (White/Nonwhite) to three (White/Black/Other). |
| 1979/1980 | <ul><li>Separate counts by Hispanic origin become available for the first time in 1980.</li><li>The race scheme changes from three categories (White/Black/Other) to four (White/Black/AIAN/API), splitting "Other" into American Indian/Alaska Native and Asian/Pacific Islander.</li></ul> |
| 1999/2000 | The race scheme changes from four categories to six (White/Black/AIAN/Asian/NHPI/TwoOrMore), splitting "API" into Asian and Native Hawaiian/Pacific Islander and adding a "Two or More Races" category. (The Census 2000 questionnaire was the first to allow respondents to select more than one race.) |
| 2019/2020 | Beginning with the Vintage 2021 estimates, Census introduced a new "blended base" methodology for constructing the population base used by post-2020 estimates. Rather than taking age, sex, race, and Hispanic-origin detail directly from the 2020 Census, the blended base combines the 2020 Census's total population counts with the Vintage 2020 PEP estimates' demographic detail. This was a workaround for COVID-19 delays that prevented the detailed 2020 Census data from being ready in time. (See Census's [overview of the blended base methodology](https://www.census.gov/library/stories/2023/06/blended-base-methodology.html).) This caused a difference of 0.3% in the counts of adults in the United States from previous years. Despite this being a relatively small change, it is the most conspicuous discontinuity visible in the Trend Plots below. |

### Irregularities

Collecting PEP data that spans multiple decades is surprisingly challenging. This section summarizes the work that was already done for you in this project.

#### National Counts for 1990-1999

The _intercensal_ counts for the 1990s only appear to be available _by county._ Census's website had some national totals, but they turned out to be postcensal counts or to not have the needed granularity by the age, sex, race, and Hispanic origin. Therefore, this project retrieves the per-county counts and sums them up to get national totals.

#### Racial Categorization Scheme Changes

As discussed previously, the Census has used four different racial categorization schemes since 1900. In order to make the whole table of data usuable, the newer race schemes were back-ported into the two older ones, so if you are using the whole run of the data, you can use the `race2` scheme and get consistent counts. If you are using just data from 1960 and on, you can use the `race3` scheme. Because there is no residual category such as "Nonwhite" or "Other" in the `race4` scheme, and there is no equivalent of "Two or More Races" in `race4`, the `race6` scheme could not be back-ported to the `race4` years.

#### Age Group 18-19 Years Old in 1990-2019

The PEP data are available with counts by single-year of age in most products, but not for the years from 1990-2019, which are only available by age group. Census uses a strange age grouping in which there is a "15 to 19 years" age group. This made calculating the number of _adults_ in those years more challenging. The number of 18 to 19 year olds was inferred for these using an assumption that the within-bin age distribution was uniform.

The "18 to 19 year olds" counts in years 1990-2019 are the only approximate counts anywhere in the output files. Every other count is exact.

#### Abbreviation of the American Indian/Alaska Native Group

In some years, the abbreviation for the American Indian/Alaska Native group is "AIAE" and in others it is "AIAN." This project made it consistently "AIAN" throughout.

#### 2020-2024 Monthly Files

The 2020-2024 postcensal estimates are available for every month of the year. To align with every other era's July 1 reference date, only the July estimates are used.

#### Zipped 1980s Files

Unlike all the other files sourced from Census, the 1980s RQI files are distributed in zip archives, each containing one fixed-width `.TXT` file. This pipeline downloads and extracts them from the zip archives.

## Trend Plots

![Total U.S. resident population, 1900-2024](R/plots/trend_total_allages.png)

![Total U.S. adult resident population, 1900-2024](R/plots/trend_total_adults.png)

![U.S. resident population by sex, 1900-2024](R/plots/trend_by_sex.png)

![U.S. resident population by race, 2-category scheme, 1900-2024](R/plots/trend_by_race_race2.png)

![U.S. resident population by race, 3-category scheme, 1960-2024](R/plots/trend_by_race_race3.png)

![U.S. resident population by race, 4-category scheme, 1980-1999](R/plots/trend_by_race_race4.png)

![U.S. resident population by race, 6-category scheme, 2000-2024](R/plots/trend_by_race_race6.png)

![U.S. resident population by Hispanic origin, 1980-2024](R/plots/trend_by_hispanic.png)

![U.S. resident population by age group, 1900-2024](R/plots/trend_by_agegroup.png)

## License

CC BY 4.0. See `LICENSE`.
