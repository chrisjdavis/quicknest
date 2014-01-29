<?php
    include_once('nest.api.php');
    
    $username = $_SERVER['argv'][1];
    $password = $_SERVER['argv'][2];
    
    define('USERNAME', $username);
    define('PASSWORD', $password);

    $nest = new Nest();
    
    $locations = $nest->getUserLocations();
    echo $locations[0]->outside_temperature;
    
    die();