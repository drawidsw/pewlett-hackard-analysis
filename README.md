# Overview

The Pewlett Hackard organization wishes to perform an anaysis of the impending **silver tsunami**. In a nutshell, the **silver tsunami** describes the phenomenon where the organization is faced with a lot of older near-retirement employees, whose departure could leave a big void. The organization wants to analyze the data and find out the answers to two questions:
* How many employees are nearing retirement.
* How many employees are ready to take over.

# Data Description

## Input Data

We are presented with six different datasets in form of cvs files:
* [employees](Data/employees.csv)
* [departments](Data/departments.csv)
* [department of each employee](Data/dept_emp.csv)
* [managers of each department](Data/dept_manager.csv)
* [salaries of employees](Data/salaries.csv)
* [titles of employees](Data/titles.csv)

## Data Model for RDBMS

In essence, there are two *independent* entities:
* Employees
* Departments

The first two tables describe various attributes of these independent entities. The third table ties them together by establishing a relationship (which employee belongs to which department). The fourth table describes which employees are department heads - in this case, the relationship can be viewed as *reversed* (i.e. which department is headed by which employee). The last two tables describe salaries and titles of an employee. The reason they are broken out of the employee table is because typically a **one to many** relationship exists (i.e. the same employee can have multiple titles indicating inter-department moves or career progression). Having said this, we note the **salaries table has a one to one relationship with the employees table**. This is not typical. In this case, having a separate salaries table has no functional value.

The process of breaking data into different tables and establishing a relationship between them is called **data normalization**, and it is considered to be the *rai·son d'ê·tre* of RDBMS (relational database management systems).

The data model can be described by the following **Entity Relationship Diagram** (abbreviated as ERD). As seen there, the departments and employee tables provide **dept_no** and **emp_no** as the primary keys. They also act as *source of truths* for the other tables, which reference those numbers by establishing a foreign relationship with the aforementioned two tables.

![image_name](EmployeeDB.png)

## Primary and Foreign Keys for Each Table

A primary key for a table uniquely identifies a row. There can never be two rows with the same primary key. A foreign key establishes a link between a value of a table to another table's value. This provides **referential integrity** to the whole system (for example, deleting or updating an employee's ID in the *employees* table would guarantee the same operation is performed in all tables linking back to the *employees* table, leaving the system in a *consistent state*).

The following table describes primary keys of all tables.

|  Table | Primary Key | Comments	| 
| ------ | ----------- | -------- | 
| **employees** | emp_no | Each employee is uniquely identified by its employee number |
| **departments** | dept_no | Each department is uniquely identified by its department number |
| **dept_emp** | (dept_no, emp_no) | Both department and employee guarantee uniqueness of a row since an employee could move to multiple departments during their tenure |
| **dept_manager** | (dept_no, emp_no) | Both department and employee guarantee uniqueness of a row. A) A department can have multiple managers through the course of time. B) The same employee could manage different departments (although such instance doesn't appear in this dataset, the model allows it) |
| **salaries** | emp_no | As noted earlier, this table seems to record only one salary instance of an employee; hence only employee number suffices to guarantee uniqueness |
| **titles** | (emp_no, title, from_date) | To understand why we need a tuple with three values to ensure uniqueness here: A) An employee can have multiple titles. B) An employee can have the exact same title on different dates (which can happen if they move between departments) |


# Analysis and Results

After importing the CSV files into tables in a postgres database in multiple tables and establishing a proper relationship conforming to the ERD shown above, we analyze data to answer the first question (number of employees nearing retirement) by creating three queries. The queries can be found [here](Queries/Employee_Database_challenge.sql).

* In total, there are 300,024 of all employees. This includes all retired as well as active employees.
* The first query we ran found the number of **potential employees** nearing retirement. A total of 133,776 record were found [here](Data/retirement_titles.csv). However, there are a number of issues here.
  * We should consider only active employees, i.e. those with the **to_date** of a special value **9999-01-01**.
  * An employee appears multiple times, since an employee can have multiple titles.
* In the next query, a **distinct** clause was used to find only one value for an employee (and their most recent title). A total of 90,399 records were found [here](Data/unique_titles.csv). We still haven't fixed the issue of finding only existing employees.
* Finally, data was aggregated and we determine the number of retiring employees by their titles. The aggregated data is shown [here](Data/retiring_titles.csv). 

To answer the second question on mentiorship eligibility, another query was run (described [here](Queries/Employee_Database_challenge.sql) under the comment *deliverable 2*. A total of 1,508 records were found [here](Data/mentorship_eligibility.csv)

# Further Analysis

The **Silver Tsunami** looks like an impending Armageddon. It appears that ~90K employees are nearing retirement and only ~1500 are eligible for potential mentorship, not even a small fraction of impending workforce about to drop out.

As seen before though, the number ~90K is not quite accurate, as we are not considering only active employees in the system. Let's modify our query and find the **active employees** that are about to retire as follows. We will run two queries to first find a total number and then, aggregate the number of employees by their titles.

```
-- Find the total number of active employees nearing retirement. (Note, this query runs on the emp_titles table created in the first deliverable)
drop table if exists emp_distinct_titles;
select distinct on (emp_no) emp_no,
			    first_name,
			    last_name,
			    title
into emp_distinct_titles
from emp_titles
where to_date = '9999-01-01'
order by emp_no, to_date desc;
select * from emp_distinct_titles;
```

The above query returns the number of rows as 72,458. It's much better than the original number of ~90K, but nevertheless, it's still quite a large number.

Then, we will rerun the query below to aggregate numbers by titles.

```
drop table if exists emp_distinct_titles;
select distinct on (emp_no) emp_no,
		            first_name,
			    last_name,
			    title
into emp_distinct_titles
from emp_titles
where to_date = '9999-01-01'
order by emp_no, to_date desc;
select * from emp_distinct_titles;
```

Now, we get the table below.

|  Count | Title |
| ------ | ----- | 
|25,916| Senior Engineer |
|24,926| Senior Staff |
|9,285| Engineer |
|7,636| Staff |
|3,603| Technique Leader |
|1,090| Assistant Engineer |
|2| Manager |

As seen from the above table, the biggest areas of concern are **senior staff** and **senior engineer** roles, where collectively, over 50K retirements are looming. Assuming the **staff** and **engineer** roles are ripe for promotions, we would like to find out just how many **current employees** with those titles are in the company, whose birth date is between 1955 and 1965 (so we are not counting staff and engineers who are about to retire). In fact, such a discovery would fix one obvious problem with the **mentorship eligibility** analysis, where a start birth date of 1965 was chosen arbitrarily. This left a big gap between 1955 and 1965 leaving all those eligible staff to be completely unaccounted for.

The following query would give us our answer.

```
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
where (ti.to_date = '9999-01-01') and
      (em.birth_date between '1956-01-01' and '1965-12-31') and
      (ti.title = 'Staff' or ti.title = 'Engineer')
order by em.emp_no;
select * from emp_titles;
```

This query returns 39,588 rows. It's much better now. Almost ~40K staff and engineers are ready to be promoted to take the senior staff and engineers who are about to retire. It still leaves a hole of ~10K positions at the senior levels, and the organization would have to fill the ~40K staff/engineer roles who are about to be promoted.

Further analysis could be done to determine the shortfalls for each department at every title.
