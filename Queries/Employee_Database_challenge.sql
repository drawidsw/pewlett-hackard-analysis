-- Deliverable 1: first query:
drop table if exists emp_titles;
select em.emp_no, 
	   em.first_name, 
	   em.last_name,
	   ti.title,
	   ti.from_date,
	   ti.to_date
into emp_titles
from employees as em
left join titles as ti
on em.emp_no = ti.emp_no
where (em.birth_date BETWEEN '1952-01-01' AND '1955-12-31')
order by em.emp_no;

-- Deliverable 1: second query
drop table if exists emp_distinct_titles;
select distinct on (emp_no) emp_no,
			    first_name,
			    last_name,
			    title
into emp_distinct_titles
from emp_titles
order by emp_no, to_date desc;

-- Deliverable 1: third query
drop table if exists retiring_titles;
select count(emp_no), 
       title
into retiring_titles
from emp_distinct_titles
group by title
order by count(emp_no) desc;

