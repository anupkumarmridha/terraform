<?php
<?php
// Read environment variables from .env file
if (file_exists(__DIR__ . '/.env')) {
    $lines = file(__DIR__ . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos($line, '=') !== false && strpos($line, '#') !== 0) {
            list($key, $value) = explode('=', $line, 2);
            $_ENV[trim($key)] = trim($value);
        }
    }
}

// Get RDS connection details from environment or fallback to defaults
$servername = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?: 'localhost';
$username = $_ENV['DB_USER'] ?? getenv('DB_USER') ?: 'admin';
$password = $_ENV['DB_PASS'] ?? getenv('DB_PASS') ?: '';
$dbname = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?: 'appdb';
$port = $_ENV['DB_PORT'] ?? getenv('DB_PORT') ?: 3306;

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname, $port);

// Check connection
if ($conn->connect_error) {
    die("
    <html>
    <head><title>Database Connection Failed</title></head>
    <body>
        <h1>❌ Database Connection Failed</h1>
        <div style='background-color: #f2dede; padding: 15px; border: 1px solid #ebccd1; border-radius: 4px; margin: 10px 0;'>
            <strong>Error:</strong> " . $conn->connect_error . "
        </div>
        <p><a href='javascript:history.back()'>← Go Back</a></p>
    </body>
    </html>
    ");
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>MySQL Database Connection Test</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f5f5f5; 
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background-color: white; 
            padding: 30px; 
            border-radius: 8px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
        .success { 
            background-color: #dff0d8; 
            padding: 15px; 
            border: 1px solid #d6e9c6; 
            border-radius: 4px; 
            margin: 10px 0; 
        }
        .info { 
            background-color: #d9edf7; 
            padding: 15px; 
            border: 1px solid #bce8f1; 
            border-radius: 4px; 
            margin: 10px 0; 
        }
        .error { 
            background-color: #f2dede; 
            padding: 15px; 
            border: 1px solid #ebccd1; 
            border-radius: 4px; 
            margin: 10px 0; 
        }
        table { 
            border-collapse: collapse; 
            width: 100%; 
            margin: 20px 0; 
        }
        th, td { 
            border: 1px solid #ddd; 
            padding: 12px; 
            text-align: left; 
        }
        th { 
            background-color: #f5f5f5; 
            font-weight: bold; 
        }
        .nav-links { 
            margin: 20px 0; 
            text-align: center; 
        }
        .nav-links a { 
            display: inline-block; 
            margin: 0 10px; 
            padding: 10px 20px; 
            background-color: #007bff; 
            color: white; 
            text-decoration: none; 
            border-radius: 4px; 
        }
        .nav-links a:hover { 
            background-color: #0056b3; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐬 MySQL Database Connection Test</h1>
        
        <div class="success">
            <strong>✅ Connected successfully to MySQL database!</strong>
        </div>

        <h2>📋 Connection Details</h2>
        <table>
            <tr>
                <th>Parameter</th>
                <th>Value</th>
            </tr>
            <tr>
                <td><strong>Database Server</strong></td>
                <td><?php echo htmlspecialchars($servername); ?></td>
            </tr>
            <tr>
                <td><strong>Database Name</strong></td>
                <td><?php echo htmlspecialchars($dbname); ?></td>
            </tr>
            <tr>
                <td><strong>Username</strong></td>
                <td><?php echo htmlspecialchars($username); ?></td>
            </tr>
            <tr>
                <td><strong>Port</strong></td>
                <td><?php echo htmlspecialchars($port); ?></td>
            </tr>
            <?php
            // Get instance information
            $instance_id = @file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
            $availability_zone = @file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');
            $local_ipv4 = @file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4');
            ?>
            <tr>
                <td><strong>Instance ID</strong></td>
                <td><?php echo htmlspecialchars($instance_id ?: 'Unknown'); ?></td>
            </tr>
            <tr>
                <td><strong>Availability Zone</strong></td>
                <td><?php echo htmlspecialchars($availability_zone ?: 'Unknown'); ?></td>
            </tr>
            <tr>
                <td><strong>Local IP Address</strong></td>
                <td><?php echo htmlspecialchars($local_ipv4 ?: 'Unknown'); ?></td>
            </tr>
            <?php
            // Test query to get MySQL version
            $sql = "SELECT VERSION() as version";
            $result = $conn->query($sql);
            
            if ($result && $result->num_rows > 0) {
                $row = $result->fetch_assoc();
                echo "<tr><td><strong>MySQL Version</strong></td><td>" . htmlspecialchars($row["version"]) . "</td></tr>";
            } else {
                echo "<tr><td><strong>MySQL Version</strong></td><td>Unable to retrieve</td></tr>";
            }
            ?>
            <tr>
                <td><strong>Connection Time</strong></td>
                <td><?php echo date('Y-m-d H:i:s'); ?></td>
            </tr>
        </table>

        <?php
        // Create a test table if it doesn't exist
        $sql = "CREATE TABLE IF NOT EXISTS test_connections (
            id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            connection_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            instance_id VARCHAR(255) NOT NULL,
            server_info VARCHAR(255) NOT NULL,
            user_agent TEXT,
            ip_address VARCHAR(45)
        )";

        if ($conn->query($sql) === TRUE) {
            echo '<div class="info"><strong>ℹ️ Test table "test_connections" is ready</strong></div>';
            
            // Insert a test record
            $server_info = $_SERVER['SERVER_NAME'] . ':' . $_SERVER['SERVER_PORT'];
            $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
            $ip_address = $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
            
            $stmt = $conn->prepare("INSERT INTO test_connections (instance_id, server_info, user_agent, ip_address) VALUES (?, ?, ?, ?)");
            $stmt->bind_param("ssss", $instance_id, $server_info, $user_agent, $ip_address);
            
            if ($stmt->execute()) {
                echo '<div class="success"><strong>✅ Test record inserted successfully</strong></div>';
            } else {
                echo '<div class="error"><strong>❌ Error inserting test record:</strong> ' . htmlspecialchars($conn->error) . '</div>';
            }
            
            // Show recent connections
            $sql = "SELECT * FROM test_connections ORDER BY connection_time DESC LIMIT 10";
            $result = $conn->query($sql);
            
            if ($result && $result->num_rows > 0) {
                echo '<h2>📊 Recent Database Connections</h2>';
                echo '<table>';
                echo '<tr><th>ID</th><th>Connection Time</th><th>Instance ID</th><th>Server Info</th><th>IP Address</th></tr>';
                
                while($row = $result->fetch_assoc()) {
                    echo '<tr>';
                    echo '<td>' . htmlspecialchars($row["id"]) . '</td>';
                    echo '<td>' . htmlspecialchars($row["connection_time"]) . '</td>';
                    echo '<td>' . htmlspecialchars($row["instance_id"]) . '</td>';
                    echo '<td>' . htmlspecialchars($row["server_info"]) . '</td>';
                    echo '<td>' . htmlspecialchars($row["ip_address"]) . '</td>';
                    echo '</tr>';
                }
                echo '</table>';
            }
        } else {
            echo '<div class="error"><strong>❌ Error creating test table:</strong> ' . htmlspecialchars($conn->error) . '</div>';
        }
        
        $conn->close();
        ?>

        <h2>🔗 Navigation</h2>
        <div class="nav-links">
            <a href="/">← Back to Dashboard</a>
            <a href="/mysql-connection.php">🔄 Refresh This Page</a>
            <a href="http://<?php echo $_SERVER['SERVER_NAME']; ?>:8080" target="_blank">🐳 Docker App</a>
        </div>
    </div>
</body>
</html>