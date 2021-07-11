WITH cte_region_territories AS (
  select
  level2_territory_key,
  level2_territory_full_name,
  level3_territory_full_name, -- added level3 territory info to avoid to populate NA value in dashboard.
  t.field_force
  from analytics.map_territory_hierarchy mth
  inner join analytics.dim_territory t
  on mth.level2_territory_key= t. territory_key
  where mth.sys_current_flag= true
  and t.sys_current_flag= true and t.sys_deleted_flag=false
  group by level3_territory_full_name, -- added level3 territory info to avoid to populate NA value in dashboard.
  level2_territory_full_name,
  level2_territory_key,
  t.field_force
),
 
-- added filter to show only the detailed products in Xsight reporting CD-6394
cte_dim_product as (
select * from analytics.dim_product
where product_type='Detail'
)
 
SELECT
  '-' as sys_created_on,
  '-' as sys_created_by,
  '-' as sys_created_id,
  fae.country_code as sys_tenant,
  fae.country_code,
  dct.country_name,
  dct.country_level_4 as country_group,
  dct.country_level_3 as subregion,
  dct.country_level_2 as regional_cluster,
  coalesce(dp.brand_name,'NA') as brand_name,
  coalesce(dp.product_name,'NA') as product_name,
  coalesce(vraps.account_product_segment, 'not segmented' ) AS segment,
  coalesce(mth.level1_territory_key, rt.level2_territory_key, 'NA') as territory_key,
  coalesce(mth.level1_territory_full_name, rt.level2_territory_full_name, 'NA') as territory_full_name,
  coalesce(mth.field_force,rt.field_force,mth.level3_territory_full_name, rt.level3_territory_full_name,'NA') as field_force, -- modified to populate level3 territory name when field force value is null for NA issue in dashboard
  coalesce(mth.level2_territory_key, rt.level2_territory_key,'NA') as region_key,
  coalesce(mth.level2_territory_full_name, rt.level2_territory_full_name, 'NA') as region,
  fae.email_clicked_flag,
  fae.email_opened_flag,
  fae.email_status,
  fae.email_sent_date,
  da.account_id,
  fae.email_sent_id,
  fae.product_key,
  fae.account_target_flag as target_flag,
  date_trunc('year',date(email_sent_date)) as year_start_date,
  -- dateadd(day, -1, dateadd(year,1,date_trunc('year',date(email_sent_date)))) as year_end_date,
  date_trunc('year',date(email_sent_date) + interval '1' year - interval '1' day as year_end_date,
  date_trunc('month',date(email_sent_date)) as month_start_date,
  -- dateadd(day, -1, dateadd(month,1,date_trunc('month',date(email_sent_date)))) as month_end_date,
  -- date_trunc('month', current_date) - interval 1 month as prev_mnth,
  case when date_trunc('month', current_date) = date_trunc('month', email_sent_date) then 'C'
  when date_trunc('month', current_date) - interval '1' month = date_trunc('month', email_sent_date) then 'P'
  when date_trunc('month', current_date) - interval '2' month = date_trunc('month', email_sent_date) then 'PP'
  when date_trunc('month', current_date) - interval '3' month = date_trunc('month', email_sent_date) then 'PPP'
  else NULL
  end as month_period,
  fae.employee_key
FROM analytics.DIM_ACCOUNT AS da
INNER JOIN analytics.FACT_APPROVED_EMAIL AS fae
  ON da.account_key = fae.account_key
  AND da.sys_current_flag = TRUE
LEFT JOIN cte_dim_product AS dp
  ON dp.product_key = fae.product_key
  AND dp.sys_current_flag = TRUE
LEFT JOIN analytics.vw_rep_account_product_segmentation AS vraps
  ON vraps.product_key = fae.product_key
  AND vraps.account_key = fae.account_key
LEFT JOIN analytics.map_territory_hierarchy AS mth
  ON fae.territory_key = mth.level1_territory_key
  AND mth.sys_current_flag = true
LEFT JOIN analytics.dim_territory AS dt
  ON fae.territory_key = dt.territory_key
  AND dt.sys_current_flag = true
LEFT JOIN cte_region_territories AS rt
  ON rt.level2_territory_key= fae.territory_key
LEFT JOIN analytics.dim_country as dct on dct.country_code = fae.country_code
WHERE 1=1
and fae.business_function_key != '4'
and ( fae.territory_key IS NULL OR mth.level1_territory_full_name IS NOT NULL OR rt.level2_territory_key IS NOT NULL)
 