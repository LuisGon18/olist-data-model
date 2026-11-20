# Olist Data Model

Dimensional data model for the Olist Brazilian e-commerce dataset (9 tables, ~100k orders): source profiling, 3NF ERD, Kimball star schema with SCD Type 2, medallion layer plan and DDL for DuckDB and BigQuery. *(In progress)*

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), published on Kaggle under the CC BY-NC-SA 4.0 license.

> **The data is not included in this repo.** The raw CSVs (9 files, about 120 MB) are excluded by `.gitignore`. Download them from Kaggle before running anything.

## How To Run

Requires the [DuckDB CLI](https://duckdb.org/docs/installation/).

1. Download the dataset from Kaggle and unzip the 9 CSVs into a `data/olist/` folder **next to** this repo:

   ```
   parent-folder/
   ├── data/
   │   └── olist/            ← the 9 Olist CSVs (not in this repo)
   └── olist-data-model/     ← this repo
   ```

2. Open a terminal in the repo root and start DuckDB:

   ```
   duckdb
   ```

3. Create one view per source table (the paths are relative to the repo root):

   ```
   .read sql/00_views.sql
   ```

4. Run the profiling checks:

   ```
   .read sql/queries.sql
   ```

Plain `duckdb` runs in memory, so the views disappear when you exit. To keep them between sessions, open a database file instead with `duckdb olist.duckdb`. `.gitignore` excludes `*.duckdb` files.

## Logical Model (Hypothesis)

Hypothesis of how the database model behaves based on purely each entity and atribute visual information from the .csv

```mermaid
erDiagram
    Customers ||--|| Orders : event_triggers
    Customers }o--|| Zip_prefix : is_in
    Geolocation }|--|| Zip_prefix : is_in
    Sellers }o--|| Zip_prefix : is_in
    Orders ||--|{ Order_items : contains
    Order_items  }|--|| Sellers : sold_by
    Order_payments }o--|| Orders : pay_for
    Order_items }o--|| Products : contains
    Products }|--o| Product_category_name_translation : category_translation
    Order_reviews |o--|| Orders : reviews
    Customers{
        STRING customer_id PK
        STRING customer_unique_id
        STRING customer_zip_code_prefix FK
    }
    Geolocation{
        STRING geolocation_zip_code_prefix FK
        FLOAT geolocation_lat
        FLOAT geolocation_lng
    }
    Sellers{
        STRING seller_id PK
        STRING seller_zip_code_prefix FK
    }
    Zip_prefix{
        STRING zip_code_prefix PK
        STRING zip_code_city
        STRING zip_code_state
    }
    Products{
        STRING product_id PK
        STRING product_category_name FK
        INT product_name_lenght
        INT product_description_lenght
        INT product_photos_qty
        INT product_weight_g
        INT product_length_cm
        INT product_height_cm
        INT product_width_cm
    }
    Orders{
        STRING order_id PK
        STRING customer_id FK
        STRING order_status
        TIMESTAMP order_purchase_timestamp
        TIMESTAMP order_approved_at
        TIMESTAMP order_delivered_carrier_date
        TIMESTAMP order_delivered_customer_date
        DATE order_estimated_delivery_date
    }
    Order_items{
        STRING order_id PK,FK
        INT order_item_id PK
        STRING product_id FK
        STRING seller_id FK
        TIMESTAMP shipping_limit_date
        DECIMAL price
        DECIMAL freight_value
    }
    Order_payments{
        STRING order_id PK,FK
        INT payment_sequential PK
        STRING payment_type
        INT payment_installments
        DECIMAL payment_value
    }
    Order_reviews{
        STRING review_id PK
        STRING order_id FK
        INT review_score
        STRING review_comment_title
        STRING review_comment_message
        DATE review_creation_date
        TIMESTAMP review_answer_timestamp
    }
    Product_category_name_translation{
        STRING product_category_name PK
        STRING product_category_name_english
    }
```

## Data Profiling

Each relationship in the hypothesis is tested against the data: hypothesis → checks → result → confirmed or revised. All queries are in [`sql/queries.sql`](sql/queries.sql).

### Orders ↔ Order_items

**Hypothesis :** `Orders ||--|{ Order_items`. Every item belongs to exactly one order, and every order has at least one item.

| **Check** | **Question** | **Result** | **Meaning** |
|-- | -- | -- | -- |
| 0 | Is `order_id` unique in orders? | 99,441 rows, 99,441 distinct | `order_id` is the primary key |
| 1 | Most items in one order | 21 | Many items per order |
| 2 | Orders with no items | **775** | An order can have **zero** items |
| 3a | Items with a NULL `order_id` | 0 | Every item has an order |
| 3b | Items whose `order_id` matches no order (orphans) | 0 | Every item's order exists |

**Why 775 orders have no items :**

| **Status** | **Orders** | **Reading** |
|-- | -- | -- |
| unavailable | 603 | **Business rule.** The order failed before any item was attached. |
| canceled | 164 | **Business rule.** Canceled orders can end up with no items. |
| created | 5 | **Ambiguous.** Could be orders still in progress or abandoned. |
| invoiced | 2 | **Data quality issue.** An invoiced order should have items. |
| shipped | 1 | **Data quality issue.** A shipped order must have items. |

**Result: revised.** `Orders ||--o{ Order_items`

- **`||` on the orders side :** Every item has exactly one order (checks 3a and 3b found no NULLs and no orphans).
- **`o{` on the order_items side :** An order has zero or many items. The "many" is confirmed by check 1, and the "zero" by check 2. The hypothesis assumed at least one item (`|{`), but 775 orders have none.

**Impact on the model :** Joining orders to order_items with an inner join drops 775 orders. Use a left join when counting orders, and decide in silver how to treat the 3 orders that are shipped or invoiced with no items.