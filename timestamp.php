<?php

$dbServername = "terraform-20200405171434680800000001.cbtwgkz5stlu.us-west-2.rds.amazonaws.com";
$dbUsername = "admin";
$dbPassword = "password";
$dbName = "mydb";

$conn = mysqli_connect($dbServername, $dbUsername, $dbPassword, $dbName) or die("Unable to Connect '$dbServername'");

$tm = date("D M j G:i:s T Y");
echo "$tm";

$sql = "INSERT INTO test_table (time_stamp) VALUES ('$tm');";

mysqli_query($conn, $sql);
echo "\n";

?>
