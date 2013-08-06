authors = {
	thomthom = {
		fullname = "Thomas Thomassen";
		license = "free, give him a cookie if the opportunity arises. http://www.thomthom.net/software/sketchup/cookieware/";
		urls = {
			"http://www.thomthom.net/software/sketchup/cookieware/";
			"https://bitbucket.org/thomthom";
			"https://github.com/thomthom";
			"http://sketchucation.com/forums/viewtopic.php?f=323&t=28782#thomthom";
		};
	};
	Fredo6 = {
		license = "The plugin is free, for private and commercial usage.";
	};
	jimfoltz = {
		fullname = "Jim Foltz";
		urls = {
			"https://github.com/jimfoltz"
		};
	};
}

plugins = {
	JointPushPull = {
		version = "2.0b";
		author = "Fredo6";
		t = 6708;
		dependencies = {
			"LibFredo6";
		};
	};
	ToolsOnSurface = {
		version = "1.8a";
		author = "Fredo6";
		t = 6708;
		dependencies = {
			"LibFredo6";
		};
	};
	LibFredo6 = {
		version = "4.7a";
		author = "Fredo6";
		t = 17947;
	};
	
	CleanUp3 = {
		version = "3.1.9";
		author = "thomthom";
		t = 22920;
		dependencies = {
			"TT_Lib2";
		};
	};
	["Explode All Images"] = {
		version = "1.0.0";
		author = "thomthom";
		t = 17154;
		dependencies = {
			"TT_Lib2";
		};
	};
	["Export 2d with Alpha"] = {
		version = "1.0.1";
		author = "thomthom";
		t = 30819;
		dependencies = {
			"TT_Lib2";
		};
	};
	
	["Guide Tools"] = {
		version = "1.3.0";
		author = "thomthom";
		t = 30506;
		dependencies = {
			"TT_Lib2";
		};
	};
		
	
	TT_Lib2 = {
		version = "2.6.0";
		author = "thomthom";
		t = 30503;
		source = "https://bitbucket.org/thomthom/tt-library-2/src"
	};
}