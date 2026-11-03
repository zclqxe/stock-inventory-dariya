# stock_inventory_dariya

A new Flutter project.

# STOCKFLOW – Stock Inventory Manager

## 1. Project Overview

STOCKFLOW is a stock inventory management application developed using Flutter and Firebase Cloud Firestore. The application helps users add products, monitor stock quantities, identify low-stock items, and search inventory records.

The application runs in Google Chrome using Flutter Web.

## 2. Technologies Used

- Flutter and Dart – application development
- Firebase Cloud Firestore – cloud database
- Firebase Core – Firebase initialization
- Google Fonts – interface typography
- Android Studio – development environment
- Google Chrome – application testing

**Firebase Project ID:** `stock-inventory-dariya`

## 3. Setup and Run Instructions

1. Install Flutter SDK and Android Studio.
2. Clone the repository:

   `git clone https://github.com/zclqxe/stock-inventory-dariya.git`

3. Open the project folder:

   `cd stock-inventory-dariya`

4. Install dependencies:

   `flutter pub get`

5. Configure Firebase using FlutterFire CLI and the Firebase project provided for the lab.

6. Run the application:

   `flutter run -d chrome`

Required Flutter packages:

- `firebase_core`
- `cloud_firestore`
- `google_fonts`

Firebase configuration is generated using FlutterFire CLI. No private keys or service-account credentials are included in this README.

## 4. Firestore Database Structure

The application stores inventory records in the `stockItems` collection.

| Field | Data Type | Description |
|---|---|---|
| sku | String | Unique product identifier |
| itemName | String | Product name |
| category | String | Product category |
| quantity | Number | Available stock quantity |
| unitPrice | Number | Price per unit in RM |
| reorderLevel | Number | Minimum stock threshold |

## 5. Form Validation

The Add New Stock Item form validates user input before saving data.

- SKU must follow the `STK-101` format (STK- followed by three digits).
- Item name cannot be empty.
- A product category must be selected.
- Quantity must be a valid non-negative number.
- Unit price must be a valid non-negative number.
- Reorder level must be a valid non-negative number.

Invalid input displays validation messages and prevents submission.

## 6. Advanced Search and Filtering

The inventory section provides several features:

**Keyword Search:** Users can search products by item name or SKU.

**Category Filter:** Users can display products belonging to a selected category, such as Electronics or Stationery.

**Low Stock Filter:** Products are considered low stock when:

`quantity <= reorderLevel`

**Quantity Sorting:** Inventory records can be sorted by quantity in ascending or descending order.

**Combined Search:** Keyword search, category selection, and low-stock filtering can be used together.

**Clear Filters:** Resets the selected search and filter options.

## 7. Test Log

| Test Case | Input | Expected Result | Actual Result |
|---|---|---|---|
| Invalid Form | Submit empty fields | Validation errors displayed | Passed – error messages appeared |
| Valid Firestore Save/Retrieve | Add STK-101, USB C Cable, Electronics, Qty 4, RM 19.90, Reorder 5 | Product saved and displayed in inventory | Passed – product appeared in inventory |
| Combined Search | Search `mouse`, select Electronics, enable Low Stock | Only STK-103 Wireless Mouse displayed | Passed – matching product displayed |

## 8. Screenshots

The `screenshots` folder contains evidence of application functionality.

- [Dashboard](screenshots/dashboard.png)
- [Form Validation](screenshots/validation.png)
- [Inventory List](screenshots/inventory.png)
- [Keyword Search](screenshots/search.png)
- [Category Filter](screenshots/category.png)
- [Low Stock Filter](screenshots/low_stock.png)

## 9. Conclusion

STOCKFLOW demonstrates the integration of Flutter with Firebase Cloud Firestore for inventory management. The application supports product registration, real-time inventory display, input validation, advanced searching, category filtering, quantity sorting, and low-stock monitoring.

The application was tested using Google Chrome, and the main required functions worked successfully.
