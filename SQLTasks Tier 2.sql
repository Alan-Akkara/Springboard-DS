/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT *
FROM Facilities
WHERE membercost > 0.0;


/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(membercost) AS freeuse_facility
FROM Facilities
WHERE membercost = 0.0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost > 0.0
AND membercost < ( 20 * monthlymaintenance ) /100;      


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid
IN ( 1, 5 );

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
	CASE WHEN monthlymaintenance > 100 THEN 'Expensive'
		 ELSE 'Cheap' END AS cost_category
FROM Facilities

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT * 
FROM Members
WHERE joindate 
IN (SELECT MAX(joindate) FROM Members)


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */


SELECT DISTINCT Facilities.name, firstname || ' ' || surname AS fullname
FROM Members
INNER JOIN Bookings ON Members.memid = Bookings.memid
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
WHERE Facilities.name LIKE '%Tennis Court%'
ORDER BY fullname


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */


SELECT DISTINCT f.name, m.firstname, m.surname,
CASE WHEN m.memid =0
THEN f.guestcost * b.slots
ELSE f.membercost * b.slots
END AS total_cost
FROM Facilities AS f
INNER JOIN Bookings AS b ON f.facid = b.facid
INNER JOIN Members AS m ON b.memid = m.memid
WHERE b.starttime LIKE "%2012-09-14%"
AND (
(b.memid <> 0
AND f.membercost * b.slots >30)
OR (b.memid = 0
AND f.guestcost * b.slots >30)
)
ORDER BY total_cost



/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT f.name AS facility_name,
       CASE 
           WHEN m.memid = 0 THEN f.guestcost * b.slots
           ELSE f.membercost * b.slots
       END AS total_cost
FROM Facilities f
JOIN Bookings b ON f.facid = b.facid
JOIN Members m ON b.memid = m.memid
WHERE b.bookid IN (
    SELECT bookid
    FROM Bookings
    JOIN Facilities ON Bookings.facid = Facilities.facid
    WHERE DATE(starttime) = '2012-09-14'
      AND (
          (memid = 0 AND guestcost * slots > 30)
          OR (memid <> 0 AND membercost * slots > 30)
      )
)
ORDER BY total_cost;



/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

booking_facility = bookings.merge(facilities, on='facid')

booking_facility['revenue'] = booking_facility.apply(
    lambda row: row['guestcost'] * row['slots'] if row['memid'] == 0 else row['membercost'] * row['slots'],
    axis=1
)

facility_revenue = booking_facility.groupby('name')['revenue'].sum().reset_index()

low_revenue = facility_revenue[facility_revenue['revenue'] < 1000]

low_revenue = low_revenue.sort_values(by='revenue')

print(low_revenue)



/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */


report = members.merge(
    members[['memid', 'firstname', 'surname']],
    how='left',
    left_on='recommendedby',
    right_on='memid',
    suffixes=('', '_recommender')
)

report['member_name'] = report['surname'] + ', ' + report['firstname']
report['recommender_name'] = report['surname_recommender'].fillna('') + ', ' + report['firstname_recommender'].fillna('')

final_report = report[['member_name', 'recommender_name']].sort_values(by='member_name')

print(final_report)


/* Q12: Find the facilities with their usage by member, but not guests */

member_bookings = bookings[bookings['memid'] != 0]

usage = member_bookings.merge(facilities, how='inner', left_on='facid', right_on='facid')

facility_usage = usage.groupby('name')['bookid'].count().reset_index()

facility_usage.rename(columns={'bookid': 'usage_count'}, inplace=True)

facility_usage.set_index("name").sort_values(by='usage_count', ascending=False)


/* Q13: Find the facilities usage by month, but not guests */

member_bookings = bookings[bookings['memid'] != 0].copy()

member_bookings['starttime'] = pd.to_datetime(member_bookings['starttime'])

member_bookings['year_month'] = member_bookings['starttime'].dt.to_period('M')

usage = member_bookings.merge(facilities, on='facid')

monthly_usage = usage.groupby(['year_month', 'name'])['bookid'].count().reset_index()

monthly_usage.rename(columns={'name': 'facility', 'bookid': 'usage_count'}, inplace=True)

monthly_usage = monthly_usage.sort_values(by='year_month')

print(monthly_usage)
