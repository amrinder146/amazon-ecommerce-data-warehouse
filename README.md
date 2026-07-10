# Amazon India E-Commerce Data Warehouse

Built a MySQL star-schema data warehouse from raw Amazon India sales data, then layered Power BI dashboards on top to answer one question the raw files couldn't: *why are so many orders getting cancelled?*

## The problem

The source data (Kaggle, ~176K rows across three files — main sales, international sales, and a product master) was messy in the way real business data usually is: inconsistent date formats, duplicate product references, and no way to slice revenue by fulfilment type without a lot of manual spreadsheet work. Nobody had modelled it, so every question meant starting from scratch.

## What I built

- **Staging → clean → star schema pipeline** in MySQL: raw tables loaded as-is, then cleaned into a typed `sales_clean` table, then split into four dimensions (`dim_date`, `dim_product`, `dim_location`, `dim_channel`) and one fact table (`fact_sales`, 128,975 rows, zero orphaned foreign keys — I checked).
- **A three-phase ETL script** (extract / transform / load) instead of one giant SQL file, so each stage can be run, checked, and reconciled independently. Row counts are validated at every handoff.
- **Two Power BI dashboards** on top of the warehouse covering sales performance and cancellation drivers.

## What it found

Total revenue across the dataset came out to ₹79M, average order value ₹652.88, and an overall cancellation rate of 15.84%. The interesting part was underneath that number: merchant-fulfilled orders cancel at 22.81%, versus 12.79% for Amazon-fulfilled (FBA) orders — almost double. That's the kind of insight that only shows up once you've actually modelled fulfilment as its own dimension instead of leaving it buried in a flat file.

## Stack

MySQL 8 · SQL · Power BI · star schema / dimensional modelling (Kimball approach)

## Repo structure

```
├── etl/                  # extract, transform, load SQL scripts (run in order)
├── powerbi/              # .pbix file + dashboard screenshots
```

## Data source

E-Commerce Sales Dataset (Amazon India), via Kaggle: [The Devastator, 2022](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data)
