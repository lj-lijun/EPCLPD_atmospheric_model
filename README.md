# EPCLPD Atmospheric Correction Model — User Manual

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Scientific Background](#2-scientific-background)
3. [Directory Structure](#3-directory-structure)
4. [Dependencies](#4-dependencies)
5. [Data Preparation](#5-data-preparation)
6. [Parameter Configuration](#6-parameter-configuration)
7. [Operation Workflow](#7-operation-workflow)
8. [Output Files](#8-output-files)
9. [Visualization](#9-visualization)
10. [Accuracy Assessment](#10-accuracy-assessment)
11. [FAQ](#11-faq)
12. [References](#12-references)

---

## 1. Project Overview

This program implements the **Empirical Photon-Centric LiDAR Path Delay (EPCLPD)** atmospheric correction model for spaceborne photon-counting LiDAR. Based on the Ciddor (1996) atmospheric refractivity formula, combined with ERA5 reanalysis meteorological data and the GPT3 empirical tropospheric model, the program computes the atmospheric path delay experienced by ICESat-2/ATLAS laser pulses (532 nm) as they traverse the atmosphere. The results are cross-validated against the GATLPD (Global Atmospheric Tide LiDAR Path Delay) correction embedded in the ATL03 data product.

### Key Features

| Feature | Description |
|---------|-------------|
| Refractivity Coefficient Calculation | Computes dry/wet refractivity coefficients N_d, N_w based on the Ciddor formula |
| ATL03 Data Extraction | Extracts reference photon geolocation and atmospheric delay from ICESat-2 ATL03 HDF5 files |
| ERA5 Meteorological Interpolation | Interpolates ERA5 pressure-level meteorological parameters to each photon location |
| Atmospheric Delay Computation | Computes EPCLPD path delay via vertical integration of the refractivity profile |
| Temporal Interpolation | Maps ERA5 hourly delays to exact photon UTC times via cubic spline interpolation |
| Accuracy Assessment | Computes MAE, RMSE, Bias, and R between EPCLPD and GATLPD |
| Visualization | Generates trajectory maps, density scatter plots, and meteorological field maps |

---

## 2. Scientific Background

### 2.1 Atmospheric Refraction Delay Principle

The ATLAS laser altimeter aboard ICESat-2 emits 532 nm laser pulses. As photons travel through the atmosphere, variations in the atmospheric refractive index cause path bending and propagation delay. The atmospheric refraction path delay \(\Delta L\) can be expressed as the vertical integral of refractivity \(N\) along the propagation path:

\[\Delta L = \int_{0}^{H_{top}} N(z) \cdot dz\]

where refractivity \(N\) consists of dry-air and wet-air components:

\[N = \frac{N_d \cdot P_d + N_w \cdot P_w}{T} \cdot Z\]

- \(N_d\): Dry-air refractivity coefficient (8.2365383 × 10⁻⁷, @532 nm)
- \(N_w\): Wet-air refractivity coefficient (-9.8383846 × 10⁻⁸, @532 nm)
- \(P_d\): Dry-air partial pressure (Pa)
- \(P_w\): Water vapor partial pressure (Pa)
- \(T\): Temperature (K)
- \(Z\): Air compressibility factor

### 2.2 Refractivity Coefficients

The refractivity coefficients \(N_d\) and \(N_w\) are computed based on the **Ciddor (1996)** formula, which provides the atmospheric refractive index as a function of wavelength, pressure, temperature, and humidity. The script `calculate_nd_nw_main.m` computes the coefficients over the wavelength range 0.23–1.69 μm, with specific annotations for ICESat-2 (532 nm) and ICESat-1 (1064 nm).

### 2.3 Model Comparison

| Model | Data Source | Characteristics |
|-------|------------|-----------------|
| GATLPD | Embedded in ATL03 product | Based on global atmospheric tide model |
| EPCLPD | ERA5 + GPT3 + Ciddor | Empirical model based on reanalysis meteorological data |

---

## 3. Directory Structure

```
EPCLPD_atmospheric_model/
│
├── calculate_nd_nw_main.m          # [Entry 1] Refractivity coefficient calculation (Ciddor formula)
├── main_experiments.m              # [Entry 2] Main experimental pipeline (ATL03 + ERA5 + validation)
│
├── plot_Correlation_atm_delay.m    # Scatter plot function (v1)
├── plot_Correlation_atm_delay_v2.m # Scatter plot function (v2, recommended)
├── plot_EPCLPD_GATLPD_cor.m        # Accuracy assessment + scatter correlation plot
├── plot_nc_map.m                   # ERA5 meteorological field global map
├── plot_trajectory_map.m           # ICESat-2 ground track map
│
├── icesat2code/                    # Core computational modules
│   ├── main.m                      # Simplified single-file processing entry point
│   ├── ICESAT_2_main.m             # Main atmospheric delay computation function
│   ├── read_atl03_gtx_atm_v.m      # ATL03 HDF5 data reader
│   ├── ERA5_cal_Meteorological_para.p  # (P-code) ERA5 meteorological parameter interpolation
│   ├── ERAdata_2_Site_data.p       # (P-code) ERA5 grid-to-point extraction
│   ├── interpo_Inverse.p           # (P-code) Inverse distance interpolation
│   ├── cal_aircompression_ratio.m  # Air compressibility factor Z calculation
│   ├── cal_delt_L.m                # Refractivity profile vertical integration
│   ├── Interp_deltL_2_deltL.m      # ERA5 time → photon time spline interpolation
│   ├── gpt3_1.m                    # GPT3 empirical tropospheric model
│   ├── gpt3_1.grd                  # GPT3 5°×5° grid file
│   ├── nclCM_Data.mat              # NCL colormap data
│   └── convert_days_to_date.m      # Date conversion utility
│
├── m_map/                          # M_Map mapping toolbox (third-party, v1.4)
│   └── (~200 files)
│
├── wordshpfile/                    # World country boundary shapefiles
│   └── country.shp / .shx / .dbf / .prj
│
├── atl03_data/                     # [User Input] Place ATL03 HDF5 files here
├── era5_data/                      # [User Input] Place ERA5 NetCDF files here
├── figure/                         # [Program Output] Figure output directory
├── results/                        # [Program Output] Intermediate results (.mat / .csv)
│
└── README.md                       # Project overview
```

---

## 4. Dependencies

### 4.1 Software Requirements

| Software | Version | Notes |
|----------|---------|-------|
| MATLAB | R2018b or later | R2020a+ recommended |
| Mapping Toolbox | Optional | If unavailable, `m_map` provides partial substitute functionality |

### 4.2 Bundled Two-Party Toolboxes

The following two-party toolboxes are included in the project and **require no separate installation**:

- **M_Map v1.4** (`m_map/`): A MATLAB mapping toolbox for plotting global track maps and meteorological field maps.
- **GPT3** (`icesat2code/gpt3_1.m` + `gpt3_1.grd`): Global Pressure and Temperature empirical model developed by TU Wien.

### 4.3 P-code Files

The following three files are provided in `.p` format (obfuscated). The source code is not human-readable but the functions can be called directly:

- `ERA5_cal_Meteorological_para.p`: Interpolates ERA5 meteorological parameters to photon locations
- `ERAdata_2_Site_data.p`: Extracts ERA5 grid data to site points
- `interpo_Inverse.p`: Inverse distance weighted interpolation

---

## 5. Data Preparation

### 5.1 ICESat-2 ATL03 Data

**Source**: [NSIDC ICESat-2 Data Portal](https://nsidc.org/data/icesat-2)

**File format**: HDF5 (`.h5`)

**Storage location**: Place downloaded ATL03 HDF5 files in subdirectories under `atl03_data/`, organized by orbit number:

```
atl03_data/
└── ATL03_20220301_105314_051036_063751/
    └── ATL03_20220301_105314_051036_063751_01.h5
```

**File naming convention**: ATL03\_`YYYYMMDD`\_`HHMMSS`\_`RRRRNN`\_`RRRRNN`.h5

- `YYYYMMDD`: Date
- `HHMMSS`: UTC time
- `RRRRNN`: Orbit/cycle number

### 5.2 ERA5 Reanalysis Data

**Source**: [ECMWF Copernicus CDS](https://cds.climate.copernicus.eu/)

**File format**: NetCDF (`.nc`)

**Required variables** (pressure-level data):

| Variable | Abbreviation | Unit | Description |
|----------|-------------|------|-------------|
| Temperature | t | K | Temperature at each pressure level |
| Specific humidity | q | kg/kg | Specific humidity at each pressure level |
| Geopotential | z | m²/s² | Geopotential at each pressure level |
| Pressure level | level | hPa | Pressure levels (37 levels) |

**Storage location**: Place all `.nc` files into the `era5_data/` directory.

> **Note**: The temporal coverage of ERA5 data should encompass the ATL03 observation period (recommended ±3 hours), and the spatial coverage should span the ICESat-2 ground track.

### 5.3 GPT3 Grid File

**File**: `icesat2code/gpt3_1.grd`

This file is included with the program and requires **no additional download**. Ensure it exists under the `icesat2code/` directory and that the path is correctly specified in the scripts.

---

## 6. Parameter Configuration

All parameters are configured via hardcoded variables at the top of `main_experiments.m`. The following key variables must be modified before execution:

### 6.1 Path Configuration

```matlab
% ATL03 data root directory
path = 'D:\...\atl03_data\';

% ERA5 data directory
nc_folder = 'D:\...\era5_data';

% GPT3 grid file path
gpt31_path = 'D:\...\icesat2code\gpt3_1.grd';

% Results output path
save_path = 'D:\...\results\';
```

### 6.2 Orbit Selection

```matlab
% Orbit folder list (supports batch processing of multiple orbits)
folder_list = "ATL03_20220301_105314_051036_063751";
% folder_list = ["ATL03_20220301_105314_051036_063751";
%                "ATL03_20220701_014816_141811_154526";
%                ...];
```

### 6.3 Beam Selection

ICESat-2 has 6 laser beams (3 strong/weak beam pairs). Use `gtx_Mask` to select the desired beams:

```matlab
% gtx_Mask = [gt1r, gt1l, gt2r, gt2l, gt3r, gt3l]
% 1 = select beam, 0 = skip
gtx_Mask = [0, 0, 1, 0, 0, 0];   % Select gt2r only (strong beam 2, right)
```

| Beam Name | Index | Type |
|-----------|-------|------|
| gt1r | 1 | Strong beam 1, right |
| gt1l | 2 | Weak beam 1, left |
| gt2r | 3 | Strong beam 2, right |
| gt2l | 4 | Weak beam 2, left |
| gt3r | 5 | Strong beam 3, right |
| gt3l | 6 | Weak beam 3, left |

### 6.4 Data Sampling

```matlab
interv = [];      % Empty = sample 1 out of every 100 photons (default downsampling)
                  % 0 or a specific value = sample at the specified interval
                  % Positive integer n = uniformly sample approximately n points
```

### 6.5 Latitude Filtering

```matlab
min_lat = [];     % Minimum latitude threshold; empty = no filtering
max_lat = [];     % Maximum latitude threshold; empty = no filtering
                  % Only photons with latitude in [min_lat, max_lat] are processed
```

### 6.6 Refractivity Coefficients (ICESAT_2_main.m)

When using laser data at wavelengths other than ICESat-2's 532 nm, modify the refractivity coefficients in `icesat2code/ICESAT_2_main.m`:

```matlab
% ICESat-2 (532 nm)
nd = 8.2365383e-7;
nw = -9.8383846e-8;

% ICESat-1 (1064 nm) — if needed
% nd = 7.8147358e-7;
% nw = -1.0604128e-7;
```

---

## 7. Operation Workflow

### 7.1 Complete Pipeline (Recommended)

Use `main_experiments.m` to execute the full five-step processing pipeline:

**Step 1: Process ATL03 Data**

1. Launch MATLAB and set the working directory to the project root.
2. Place ATL03 `.h5` files into subdirectories under `atl03_data/`, organized by orbit.
3. Configure `path`, `folder_list`, `gtx_Mask`, and `save_path` in `main_experiments.m`.
4. Execute Step 1 (lines 23–159): select the code block and press `F9` to run.

> **Output**: `<orbit>_gtx_atm_refph_info.mat` and `<orbit>_lat_lon_elevation_pd.csv`

5. After the program pauses, press any key to continue.

**Step 2: Process ERA5 Data**

6. Ensure ERA5 `.nc` files are placed in the `era5_data/` directory.
7. Configure `nc_folder` and `gpt31_path`.
8. Execute Step 2 (lines 161–195).

> **Output**: `era5-<date>_gtx_ph_met_info.mat`

**Step 3: Compute Atmospheric Delay**

9. Execute Step 3 (lines 199–208): calls `ICESAT_2_main()` to compute the EPCLPD atmospheric path delay.

> **Output**:
> - `era5-<date>_Atm_delt_L.mat`: Atmospheric delay at ERA5 epoch times
> - `era5-<date>_interp_delt_L.mat`: Delay interpolated to photon UTC times

### 7.2 Refractivity Coefficient Calculation Only

To independently compute refractivity coefficients at various wavelengths:

1. Open `calculate_nd_nw_main.m`.
2. Modify the wavelength range if needed: `Lamda = 0.23:0.01:1.69;` (unit: μm).
3. Run the script. It will output plots of N_d(λ), N_w(λ), and N(λ), with annotated coefficient values at 532 nm and 1064 nm.

### 7.3 Simplified Single-File Processing

`icesat2code/main.m` provides a simplified entry point suitable for quick testing with a single pair of data files. Modify the hardcoded paths within the script before use.

### 7.4 Processing Flowchart

```
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  ATL03 HDF5 Data │   │ ERA5 NetCDF Data │   │  GPT3 Grid File  │
└────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                      │                      │
         ▼                      ▼                      ▼
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ read_atl03_gtx    │   │ ERA5_cal_Meteo   │   │    gpt3_1.m      │
│ _atm_v.m          │   │ rological_para.p │   │                  │
│                   │   │                  │   │ Provides aux.    │
│ Extracts photon   │   │ Interpolates     │   │ meteorological   │
│ position, height, │   │ T, Q, P, H to   │   │ parameters       │
│ UTC time, GATLPD  │   │ photon locations │   │ (pressure, temp, │
│ delay             │   │                  │   │  lapse rate)     │
└────────┬──────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                      │                        │
         │             ┌────────┴────────┐               │
         │             │ gtx_ph_met_info │◄──────────────┘
         │             │ (met. param.    │
         │             │  struct)        │
         │             └────────┬────────┘
         │                      │
         │                      ▼
         │             ┌──────────────────┐
         │             │  ICESAT_2_main   │
         │             │                  │
         │             │ 1. Compute Pd, Pw│
         │             │ 2. Compute compr.│
         │             │    factor Z      │
         │             │ 3. Compute refr. │
         │             │    index N       │
         │             │ 4. Vertical      │
         │             │    integration ΔL│
         │             └────────┬─────────┘
         │                      │
         │                      ▼
         │             ┌──────────────────┐
         │             │ Interp_deltL_2   │
         │             │ _deltL.m         │
         │             │                  │
         │             │ Spline interp.:  │
         │             │ ERA5 epoch →     │
         │             │ photon UTC       │
         │             └────────┬─────────┘
         │                      │
         └──────────┬───────────┘
                    │
                    ▼
           ┌──────────────────┐
           │ Accuracy Assess. │
           │ & Visualization  │
           │                  │
           │ MAE, RMSE, Bias  │
           │ Density scatter  │
           │ Trajectory map   │
           └──────────────────┘
```

---

## 8. Output Files

### 8.1 Intermediate Results (.mat files)

| Filename | Content | Key Fields |
|----------|---------|------------|
| `<orbit>_gtx_atm_refph_info.mat` | Reference photon information extracted from ATL03 | `Ph_UTC_Time`, `Ref_Ph_Lat`, `Ref_Ph_Lon`, `Ref_Ph_Ht`, `Ref_PD_total` |
| `era5-<date>_gtx_ph_met_info.mat` | ERA5 meteorological parameters interpolated to photon locations | `T_i` (temperature), `Q_i` (specific humidity), `P_i` (pressure), `H_i` (geopotential height) |
| `era5-<date>_Atm_delt_L.mat` | EPCLPD atmospheric delay at ERA5 epoch times | `Atm_delt_L` (matrix: n_photons × n_times) |
| `era5-<date>_interp_delt_L.mat` | EPCLPD atmospheric delay at photon UTC times | `interp_delt_L` (vector: n_photons × 1) |

### 8.2 Tabular Output (.csv files)

| Filename | Columns |
|----------|---------|
| `<orbit>_lat_lon_elevation_pd.csv` | `lon` (longitude), `lat` (latitude), `h` (elevation), `pd` (GATLPD path delay) |

### 8.3 Figure Output (.png files)

All figures are saved to the `figure/` directory by default, at 600 dpi resolution.

---

## 9. Visualization

### 9.1 Accuracy Assessment Scatter Plot

**Script**: `plot_EPCLPD_GATLPD_cor.m`

Generates a density scatter plot of EPCLPD (modeled values) vs. GATLPD (reference values), annotated with R, Bias, and RMSE.

**Execution steps**:
1. Modify the `.mat` file loading paths in the script:
   ```matlab
   gtx_atm_refph_info_path = '...\results\<orbit>_gtx_atm_refph_info.mat';
   globalinterp_delt_L_path = '...\results\era5-<date>_interp_delt_L.mat';
   ```
2. Run the script.
3. The console outputs MAE, RMSE, Bias, maximum, and minimum values.
4. A density scatter plot is generated and automatically saved.

**Outlier filtering**: The 2.5 × IQR criterion is applied by default to filter outliers.

### 9.2 Ground Track Map

**Script**: `plot_trajectory_map.m`

Plots the ICESat-2 ground track on a Miller-projection world map, colored by atmospheric delay magnitude.

**Calling convention** (automatically invoked in `main_experiments.m`):
```matlab
plot_trajectory_map(Ref_Ph_Lon, Ref_Ph_Lat, Ref_PD_total, fileout_trajectory_map)
```

### 9.3 ERA5 Meteorological Field Map

**Script**: `plot_nc_map.m`

Visualizes the global distribution of ERA5 variables such as temperature, specific humidity, and pressure.

### 9.4 Scatter Plot Function

**General-purpose function**: `plot_Correlation_atm_delay_v2.m`

```matlab
plot_Correlation_atm_delay_v2(x, y, Xlable, Ylable, Legend, fileout, png_name)
```

| Parameter | Description |
|-----------|-------------|
| `x` | X-axis data (modeled EPCLPD values) |
| `y` | Y-axis data (reference GATLPD values) |
| `Xlable` | X-axis label string |
| `Ylable` | Y-axis label string |
| `Legend` | Legend label |
| `fileout` | Output file path (without extension) |
| `png_name` | Figure title |

---

## 10. Accuracy Assessment

### 10.1 Evaluation Metrics

The program automatically computes the following metrics (in `plot_EPCLPD_GATLPD_cor.m`):

| Metric | Formula | Interpretation |
|--------|---------|----------------|
| MAE (Mean Absolute Error) | \(\frac{1}{n}\sum\|\hat{y}_i - y_i\|\) | Average magnitude of model error |
| RMSE (Root Mean Square Error) | \(\sqrt{\frac{1}{n}\sum(\hat{y}_i - y_i)^2}\) | Square-root average of squared errors; more sensitive to large errors |
| Bias (Mean Error) | \(\frac{1}{n}\sum(\hat{y}_i - y_i)\) | Direction and magnitude of systematic model bias |
| R (Correlation Coefficient) | \(\frac{\text{cov}(\hat{y}, y)}{\sigma_{\hat{y}}\sigma_y}\) | Linear correlation between modeled and reference values |

### 10.2 Outlier Filtering

The **2.5 × IQR** criterion is applied by default:

```matlab
Q1 = quantile(errors, 0.25);
Q3 = quantile(errors, 0.75);
IQR = Q3 - Q1;
lower_bound = Q1 - 2.5 * IQR;
upper_bound = Q3 + 2.5 * IQR;
```

The multiplier can be adjusted as needed (e.g., changed to `1.5` or `3.0`).

---

## 11. FAQ

### Q1: Runtime error "这不是一个文件夹" ("This is not a folder")

**Cause**: The ATL03 subdirectory specified in `folder_list` does not exist under `path`.

**Solution**: Verify that the folder name in `folder_list` matches the actual directory name and that the folder has been placed under `atl03_data/`.

### Q2: Interpolation error "插值日期不在时间范围内" ("Interpolation date out of temporal range")

**Cause**: The temporal coverage of the ERA5 data does not encompass the ATL03 observation time.

**Solution**:
- Check that the ERA5 timestamps cover the photon observation time ±3 hours.
- The `hours(3)` tolerance in `Interp_deltL_2_deltL.m` can be increased (but extending beyond 6 hours is not recommended).

### Q3: P-code files cannot be invoked

**Cause**: The P-code files are incompatible with the current MATLAB version.

**Solution**:
- P-code files are bound to the MATLAB version under which they were created. Large version gaps (e.g., P-code from R2015b running under R2023a) may cause incompatibility.
- Ensure the P-code file paths have been added to the MATLAB search path.

### Q4: Out of memory

**Cause**: A single ATL03 orbit contains millions of reference photons.

**Solution**:
- Increase the `interv` parameter to reduce the sampling rate. When `interv = []`, the default is 1 out of every 100 photons.
- Set latitude filtering (`min_lat`, `max_lat`) to narrow the processing extent.
- Use `gtx_Mask` to process only a subset of beams.

### Q5: How do I add the MATLAB search path?

Run the following in the MATLAB Command Window:

```matlab
addpath(genpath('D:\...\EPCLPD_atmospheric_model'));
savepath;
```

### Q6: m_map toolbox errors

**Cause**: The m_map path is not correctly added, or shapefiles are missing.

**Solution**:
- Ensure the `m_map/` directory is on the MATLAB search path.
- Verify that the `wordshpfile/country.shp` file set is complete (`.shp`, `.shx`, and `.dbf` must all be present).

---

## 12. References

1. **Ciddor, P. E.** (1996). Refractive index of air: new equations for the visible and near infrared. *Applied Optics*, 35(9), 1566–1573.

2. **Neuenschwander, A., & Pitts, K.** (2019). The ATL08 land and vegetation product for the ICESat-2 Mission. *Remote Sensing of Environment*, 221, 247–259.

3. **Böhm, J., Möller, G., Schindelegger, M., Pain, G., & Weber, R.** (2015). Development of an improved empirical model for slant delays in the troposphere (GPT2w). *GPS Solutions*, 19(3), 433–441.

4. **Dolloff, J., Luthcke, S., Morison, J., & Carabajal, C.** (2020). ICESat-2 Algorithm Theoretical Basis Document (ATBD) for ATL03.

5. **Hersbach, H., et al.** (2020). The ERA5 global reanalysis. *Quarterly Journal of the Royal Meteorological Society*, 146(730), 1999–2049.

6. **Markus, T., et al.** (2017). The Ice, Cloud, and land Elevation Satellite-2 (ICESat-2): Science requirements, concept, and implementation. *Remote Sensing of Environment*, 190, 260–273.

---

## Appendix A: Module Dependency Graph

```
main_experiments.m
├── read_atl03_gtx_atm_v.m               # ATL03 HDF5 reader
├── ERA5_cal_Meteorological_para.p        # ERA5 meteorological interpolation (calls below)
│   ├── ERAdata_2_Site_data.p
│   ├── interpo_Inverse.p
│   └── gpt3_1.m + gpt3_1.grd
├── ICESAT_2_main.m                      # EPCLPD delay computation
│   ├── cal_aircompression_ratio.m
│   └── cal_delt_L.m
├── Interp_deltL_2_deltL.m               # Temporal interpolation
├── plot_trajectory_map.m                # Ground track map
│   ├── m_map/
│   ├── colormap_nclCM/
│   └── wordshpfile/
└── plot_EPCLPD_GATLPD_cor.m             # Accuracy assessment figure
    └── plot_Correlation_atm_delay_v2.m
```

---

## Appendix B: Typical Runtime

| Step | Data Volume | Estimated Time |
|------|------------|----------------|
| ATL03 extraction | 1 orbit, ~5M photons (downsampled to ~50k) | ~30 s |
| ERA5 meteorological interpolation | 50k photons × 37 levels × 24 epochs | ~5–10 min |
| Refractivity computation + integration | Same as above | ~2–5 min |
| Temporal interpolation | 50k photons | ~1–2 min |

> The above times are estimates; actual speed depends on CPU performance and MATLAB version.

---

*Document last updated: June 2026*
