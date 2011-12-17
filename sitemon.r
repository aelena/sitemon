REBOL [
	Title: "SiteMon - monitor your sites and email alerts"
	Date: 17-Dec-2011
	Name: SiteMon 0.1.0 ; this shows in the header
	File: %sitemon.r
	Version: 0.1.0
	Author: "Antonio Elena (from code by Carl Sassenrath)"
	Home: www.aelena.com
	Needs: [view 1.3.1]
	
	Purpose: {
		quick and dirty monitoring of sites, web services, etc
		emails alert when any system goes down
	}
	
	Note: { 
		Modify to your soul's content
	}
	
	History: {
		0.1.0 [17-Dec-2011: "Initial Version" ]
	}
]

time-out: 5  ; Seconds to wait for the connection (adjust it!)
poll-time: 0:10:00

environments: array 0
systems: []

system/schemes/default/timeout: time-out
system/schemes/http/timeout: time-out
system/schemes/https/timeout: time-out

; list of emails to be notified of systems being down
notify-emails: [
	youremail@gmail.com
	yourotheremail@gmail.com
]

; array of sites
; we can do an double array like this, 2 because we have 2 environments to monitor   (QA and PROD)
; and 3 because so far we will be monitoring three systems on these environments
; sites: array [2 3]
; but it's better to use an associative array
; define environments on the leftmost item, put machines in between brackets, like so:
sites: [
	QA 
	[
		http://www.aelena.com
		http://www.google.com
		http://www.flickr..com
	]
	PROD 
	[
		http://www.twitter.com
		http://www.google.com
		http://www.flickr.com
	]
	XI
	[]
]

out: [
		backeffect [gradient 0x1 water mint]
]


; iterate the block above, if the item is a block in itself
; store it in the systems array, otherwise keep on the environment list
foreach env sites [
	print env
	either block? env
	[
		foreach site env [
			append systems site
						
			if find/match site http:// [
				
				insert remove/part site 7 tcp://
				append site ":80"

				port: make port! site
				append out compose/deep [
					image img (port/host) [check-site face] [browse face/data]
					with [data: (site)]
				]				
			]		
		]
	]
	[
		_env: make string! env
		;_env2: copy _env
		;print same? _env _env2
		append environments env
		;append out [label _env]
		append out 
		[  
			text as-is font-size 11 center 200 white make string! env 
		]
	]	
]

; notify the user in the console if everything is ok
print "After processing configuration, the list of environments is: "
probe environments
print "And the URLs of the systems to monitor are: "
probe systems

img: make image! [260x40 0.0.120 255]
draw img [
	pen black
	fill-pen linear 0x2 0 44 89 1 1 silver gray coal red
	box 8.0 0x0 199x39
]



append out [
	pad 50x0
	btn water 100 "Refresh" rate poll-time feel [
		engage: func [f a e] [if find [time down] a [check-sites]]
	]
]

emailbody: func []
[
		emit 
		[
			<BODY><HTML><B><BR/>
		 	"System" x  " is down!"
			</B><BR/>
			"Please restart the service or contact the appropiate support."
			<BR/>
			"Thanks, the XYZ team."
			</BODY></HTML>
		] 
]

header: make system/standard/email [
    Subject: "SYSTEM DOWN!"
    Organization: "W4E"
]


sendwarning: func [x [string!]] [
	send/only notify-emails 	
	[
			<BODY><HTML><B><BR/>
		 	"System" x  " is down!"
			</B><BR/>
			"Please restart the service or contact the appropiate support."
			<BR/>
			"Thanks, the XYZ team."
			</BODY></HTML>
		]
	

]

color-face: func [face color] [
	face/effect: reduce ['colorize color]
	show face
]

check-site: func [face] [
	color-face face gray
	color-face face either attempt [close open face/data true]
	[green]
	[
		red
		print "about to send the email!"
		print face/text
		sendwarning face/text
	]
]

check-sites: does [
	foreach face out/pane [
		if face/style = 'image [check-site face]
	]
]


 

out: layout out
view/new out
check-sites
do-events
