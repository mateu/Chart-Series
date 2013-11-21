use AnyEvent::HTTP;
 
 http_get "http://www.nethype.de/", sub { print $_[1] };
 http_get "http://google.com/", sub { print $_[1] };
