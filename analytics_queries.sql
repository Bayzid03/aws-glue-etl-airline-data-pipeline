### **Top Delayed Routes**
```
SELECT 
    dep_city || ' → ' || arr_city AS route,
    carrier,
    COUNT(*) AS delay_count,
    AVG(dep_delay) AS avg_departure_delay,
    AVG(arr_delay) AS avg_arrival_delay
FROM airlines.daily_flights_fact
GROUP BY dep_city, arr_city, carrier
HAVING COUNT(*) >= 10
ORDER BY avg_departure_delay DESC
LIMIT 20;
```

### **Carrier Performance by State**
```
SELECT 
    carrier,
    dep_state,
    COUNT(*) AS total_delayed_flights,
    AVG(dep_delay) AS avg_delay_minutes
FROM airlines.daily_flights_fact
GROUP BY carrier, dep_state
ORDER BY total_delayed_flights DESC;
```

### **Airport Delay Hotspots**
```
SELECT 
    dep_airport,
    dep_city,
    dep_state,
    COUNT(*) AS departure_delays,
    ROUND(AVG(dep_delay), 2) AS avg_delay_min
FROM airlines.daily_flights_fact
GROUP BY dep_airport, dep_city, dep_state
ORDER BY departure_delays DESC
LIMIT 15;
```
