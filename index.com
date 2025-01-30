<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Transaction Information</title>
<style>
    table {
        border-collapse: collapse;
        width: 100%;
    }

    th, td {
        border: 1px solid black;
        padding: 8px;
        text-align: left;
    }

    th {
        background-color: #f2f2f2;
    }
</style>
<script>
function getTransactionInfo() {
    var address = document.getElementById("addressInput").value;
    var xhr = new XMLHttpRequest();
    var url = "https://api.scan.pulsechain.com/api?module=account&action=txlist&address=" + address + "&sort=asc";

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                var transactions = data.result;
                var output = document.getElementById("transactionInfo");
                output.innerHTML = ""; // Clear previous results

                // Create table
                var table = document.createElement("table");
                var headerRow = table.insertRow();
                var headers = ["From", "To", "Value", "Timestamp"];
                headers.forEach(function(headerText) {
                    var header = document.createElement("th");
                    header.textContent = headerText;
                    headerRow.appendChild(header);
                });

                // Initialize an array to store unique addresses
                var uniqueAddresses = [];

                transactions.forEach(function(tx) {
                    if (tx.input === "0x") {
                        var row = table.insertRow();
                        var rowData = [tx.from, tx.to, tx.value, new Date(tx.timeStamp * 1000).toLocaleString()];
                        
                        // Check if "to" address matches the input address
                        if (tx.to.toLowerCase() === address.toLowerCase()) {
                            row.style.color = "green"; // Set color to green
                        } else {
                            row.style.color = "blue"; // Set color to blue
                        }

                        // Add "from" and "to" addresses to uniqueAddresses array
                        if (!uniqueAddresses.includes(tx.from.toLowerCase())) {
                            uniqueAddresses.push(tx.from.toLowerCase());
                        }
                        if (!uniqueAddresses.includes(tx.to.toLowerCase())) {
                            uniqueAddresses.push(tx.to.toLowerCase());
                        }

                        rowData.forEach(function(cellData) {
                            var cell = row.insertCell();
                            cell.textContent = cellData;
                        });
                    }
                });

                output.appendChild(table);

                // Display unique addresses under the table
                var uniqueAddressesList = document.createElement("div");
                uniqueAddressesList.innerHTML = "<h3>Unique Addresses:</h3>";
                var ul = document.createElement("ul");

                // Iterate over unique addresses and make API requests
                uniqueAddresses.forEach(function(address) {
                    var li = document.createElement("li");
                    li.textContent = address;
                    ul.appendChild(li);
                    
                    // Make API request for each unique address
                    var addressUrl = "https://api.scan.pulsechain.com/api?module=account&action=txlist&address=" + address + "&sort=asc";
                    var addressXhr = new XMLHttpRequest();
                    addressXhr.onreadystatechange = function() {
                        if (addressXhr.readyState === XMLHttpRequest.DONE) {
                            if (addressXhr.status === 200) {
                                var addressData = JSON.parse(addressXhr.responseText);
                                // Display address data in HTML
                                // Display address data in HTML
                                var addressInfo = document.createElement("p");
                                // Extracting and truncating input fields from the addressData
                                var truncatedInputs = addressData.result.map(function(tx) {
                                    // return tx.input;
                                    return tx.input.substring(0, 10); // Extracting the first 10 characters
                                });
                                addressInfo.textContent = "Truncated input fields for address " + address + ": " + JSON.stringify(truncatedInputs);
                                uniqueAddressesList.appendChild(addressInfo);
                            } else {
                                console.error("Error:", addressXhr.status);
                            }
                        }
                    };
                    addressXhr.open("GET", addressUrl);
                    addressXhr.send();
                });

                uniqueAddressesList.appendChild(ul);
                output.appendChild(uniqueAddressesList);
            } else {
                console.error("Error:", xhr.status);
            }
        }
    };

    xhr.open("GET", url);
    xhr.send();
}

</script>
</head>
<body>
    <h1>Green = money in and blue = money out now Transaction Information</h1>

<label for="addressInput">Enter Address:</label>
<input type="text" id="addressInput">
<button onclick="getTransactionInfo()">Get Transactions</button>
<div id="transactionInfo"></div>
</body>
</html>
