<?php

header('Content-type: text/plain');

$ep = "bidder";  # name of the magic etherpad.
$epurl = "https://padm.us/bidder/export/txt";

$content = file_get_contents($epurl);
preg_match(
  '/BEGIN_AUCTION_MAGIC(\[([^\[\]]+)\])?(.*?)END_AUCTION_MAGIC/s',
  $content, $matches);
$content = $matches[3];
$price = $matches[2]; # stuff in brackets after magic string
$price = str_replace('$', '', $price);
$price = $price ? $price : "600"; # default to amount of Melanie's contract
# Turn etherpad text (lines like "alice: 1, 2, 3") into eval'able Wolframaic
$content = str_replace('$', '', $content); # first strip out any dollar signs
$content = preg_replace('/\n\s*([^\:]+)\s*\:\s*([\d\.\ \t\,\-\/\+\*]*).*/', 
                        '{"$1",$2},', $content);
$content = "{ " . 
  "{\"MAGIC_SELLER\", " . $price . "}," .
  $content . 
  "Null }"; # final null to deal with trailing comma

$descriptorspec = array( 0 => array("pipe", "r"),
                         1 => array("pipe", "w"),
                         2 => array("pipe", "w")  );
$process = proc_open('/usr/local/bin/mash chauc.m', $descriptorspec, $pipes);
fwrite($pipes[0], $content);  # send stuff to it via stdin
fclose($pipes[0]);
echo stream_get_contents($pipes[1]); # echo stdout from the pipe
#echo "<pre>" . $content . "</pre>"; # just testing
fclose($pipes[1]);
proc_close($process);

?>
