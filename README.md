
Is your location simulation is speedy or 'jumpy'?

GPX files generated via Google maps (My maps tool) could be 'Glitchy' in a location simulation via xCode. Sometimes driver's puck is driving way to fast on some segments of your simulation, sometimes it even jumps between subsequent location instead of driving smoothly. It could happen due to poor amount of WPT on your routeline. Often it happen on a straight highways. Examples:
 
One way to smooth your location using such GPX files - add more WPTs on the routeline to not let Driver's puck jump between long-distanced WPTs. It's very inconvenient doing it manually, and also - it takes a lot of time, so there's a tool, that will get your GPX file, and return updated GPX file containing more WPTs on the route without loosing quality - WaypointInserter.


Before → After WaypointInserter
You can check the results yourself at My maps page. I'll post more as I'll use this tool more.

How to run WaypointsInserter:

1. You should have xCode
2. Download WaypointsInserter from github & open via xCode (or simply use Open with xCode option)
3. Put your input GPX file that you want to enrich in Downloads folder and rename it to inserter.gpx
4. Run WaypointsInserter xCode app. It will ask for Finder permissions - Allow them. It's just to read your inserter.gpx & write output to Downloads folder 
5. Check updated.gpx file appeared in your Downloads folder. That's it!
Feel free to check the Video (same steps recorded):



NOTE: You can change the Step variable to regulate amount of WPTs you need. By default it's 50m, which mean - app will add WPTs for each 50m. If it's too much for your purposes - you can change it to 100m, or if you'll need more waypoints (for a lower Puck's speed) - use 20 / 10m
Step variable is present on line #4 of main.swift file.

How WaypointsInserter works
For now - it's a public Github repo, 100% swift coded. All logic is stored to main.swift (it's Anton Diadiuk's TODO to improve the code, split different logic and algorithms to separate files)

1. At first - it reads your inserter.gpx file, convert it to a string and via REGEX - it reads Waypoint's Lat & Long => Store them to an CLLocationCoordinate2D array to work on it further.
2. Then, app takes pair of WPTs (like WPT#1 & WPT#2 taking WPT#1 as START & WPT#2 as END), then App interpolates from START to END by creating intermediate on a distance (STEP) == 50m by default.
3. App iterates for each pair of WPT's from the beginning of inserter.gpx to it's last WPT, resulting in an enriched CLLocationCoordinate2D array.
4. Last step - app convert resulted array into GPX file, by adding corresponding Syntax, and write it to updated.gpx file
