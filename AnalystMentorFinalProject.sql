-- display the row number
select
	t.*
	, row_number() over(partition by t.customer_id, t.trans_dt order by  t.trans_dt) as trans_hist_num
from 
	transactions t


--Summary of Quartiles
with trans_items_quartiles as(
	select
		t.*
		, ntile(4) over(order by t.items_in_trans) as quartile
	from 
		transactions t
	where 
		t.trans_dt = '2022-01-12'
)

select
	t.quartile
	, min(t.items_in_trans) as min_items_in_trans
from
	trans_items_quartiles t
group by
	t.quartile


--Statistical Summary
with transaction_totals as(
	select
		ti.transaction_id
	, sum(p.price) as total_sales
	from 
		transaction_items ti
			join products p
				on p.product_id = ti.product_id
	group by
		ti.transaction_id
)

, trans_sales as (
		select
			t.trans_dt
			, t.transaction_id
			, tt.total_sales
			, ntile(4) over(order by tt.total_sales asc) as quartile
		from
			transactions t 
				join transaction_totals tt
					on t.transaction_id = tt.transaction_id
)

, quartile_summary as (
	select
		s.quartile
	, min(s.total_sales) as total_sales
	from
		trans_sales s 
	group by
		s.quartile
	order by
		s.quartile

)

, total_sales_summary as (
	select
		avg(s.total_sales) as avg_total_sales
		, max(s.total_sales) as max_total_sales
		, min(s.total_sales) as min_total_sales
	from
		trans_sales s

)

select
	s.avg_total_sales
	, s.max_total_sales
	, s.min_total_sales
	, max(case when q.quartile = 1 then q.total_sales else 0 end) as quartile_1_total_sales
	, max(case when q.quartile = 2 then q.total_sales else 0 end) as median_total_total_sales
	, max(case when q.quartile = 3 then q.total_sales else 0 end) as quartile_3_total_sales
from
	total_sales_summary s
	, quartile_summary q
group by
	s.avg_total_sales
	, s.max_total_sales
	, s.min_total_sales


--3 day trailing average on total sales
select
	d.trans_dt
	, d.total_sales
	, cast(avg(d.total_sales) over(order by d.trans_dt rows between 2 preceding and current row) 
		    as int) as avg_trailing_3d
from
	daily_sales_summary d
order by
	d.trans_dt
	
--Finding the last day of the current month
select
	t.*
	, cast(
		date_trunc('month', trans_dt) --truncate to first day of this month
		+ interval '1 month' -- bump forward to the first day of next month
		- interval '1 day' -- subtract a day, giving us the last day of the current month
		as date) 
		as last_day_of_current_month
from 
	transactions t
	





