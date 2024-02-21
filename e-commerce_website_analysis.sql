CREATE DATABASE IF NOT EXISTS ecommerce_website_data;

CREATE TABLE IF NOT EXISTS website_sessions (
  website_session_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  created_at DATETIME NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  is_repeat_session SMALLINT UNSIGNED NOT NULL, 
  utm_source VARCHAR(12), 
  utm_campaign VARCHAR(20),
  utm_content VARCHAR(15), 
  device_type VARCHAR(15), 
  http_referer VARCHAR(30)
  );
 
 CREATE TABLE website_pageviews (
  website_pageview_id BIGINT NOT NULL PRIMARY KEY,
  created_at DATETIME NOT NULL,
  website_session_id BIGINT NOT NULL,
  pageview_url VARCHAR(50) NOT NULL
  );

SELECT * FROM website_sessions; -- imported data from Excel 

SELECT * FROM website_pageviews; -- imported data from Excel 

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- WHAT ARE THE MOST-VIEWED WEBSITE PAGES?
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS pageviews
FROM website_pageviews
GROUP BY pageview_url
ORDER BY pageviews DESC;

-- WHAT ARE THE TOP ENTRY PAGES?

-- find the first pageview for each session 
CREATE TEMPORARY TABLE first_pageview_per_session
SELECT 
	website_session_id,
	MIN(website_pageview_id) AS first_pageview 		-- because there can be multiple pageviews per session and I want the first pageview, I take the min
FROM website_pageviews
GROUP BY website_session_id;

-- find the url the customer saw on that first pageview 
SELECT 
	website_pageviews.pageview_url AS landing_page_url,
	COUNT(DISTINCT first_pageview_per_session.website_session_id) AS sessions_hitting_page
FROM first_pageview_per_session
	LEFT JOIN website_pageviews
		ON first_pageview_per_session.first_pageview = website_pageviews.website_pageview_id
GROUP BY landing_page_url; 

-- WHAT IS THE BOUNCE RATE FOR TRAFFIC LANDING ON THE HOME PAGE?

-- restrict landing page to home only (this is redunant since it showed above home is the only landing page but it will help make further analysis easier)
CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT 
	first_pageview_per_session.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_pageview_per_session 										-- temporary table from question 2
	LEFT JOIN website_pageviews
    ON website_pageviews.website_pageview_id = first_pageview_per_session.first_pageview
WHERE website_pageviews.pageview_url = '/home';	

CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	sessions_w_home_landing_page.website_session_id,
    sessions_w_home_landing_page.landing_page,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_home_landing_page
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = sessions_w_home_landing_page.website_session_id
GROUP BY 
	sessions_w_home_landing_page.website_session_id,
    sessions_w_home_landing_page.landing_page
HAVING 
COUNT(website_pageviews.website_pageview_id) = 1; -- = 1 because I want bounced sessions 

SELECT 
	COUNT(DISTINCT sessions_w_home_landing_page.website_session_id) AS total_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id)/COUNT(DISTINCT sessions_w_home_landing_page.website_session_id) AS bounce_rate
FROM sessions_w_home_landing_page
LEFT JOIN bounced_sessions
	ON sessions_w_home_landing_page.website_session_id = bounced_sessions.website_session_id;

