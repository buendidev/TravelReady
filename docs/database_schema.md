# TravelReady! - Esquema de Base de Datos SQLite

## Diagrama ER (Entity-Relationship)

```mermaid
erDiagram
    users ||--o{ trips : "1:N"
    users ||--o{ packing_lists : "1:N"
    users ||--o{ packing_items : "1:N"
    users ||--o{ chat_members : "1:N"
    users ||--o{ messages : "1:N"
    users ||--o{ user_sessions : "1:N"
    trips ||--o{ trip_transport : "1:N"
    trips ||--o{ trip_activities : "1:N"
    trips ||--o{ packing_lists : "1:N"
    packing_lists ||--o{ packing_items : "1:N"
    chats ||--o{ chat_members : "1:N"
    chats ||--o{ messages : "1:N"

    users {
        VARCHAR id PK
        VARCHAR name
        VARCHAR email UK
        VARCHAR password_hash
        VARCHAR plan
        TEXT plan_renewal_date
        TEXT created_at
        TEXT photo_url
    }

    trips {
        VARCHAR id PK
        VARCHAR user_id FK
        VARCHAR name
        VARCHAR destination
        TEXT start_date
        TEXT end_date
        VARCHAR trip_type
        INTEGER progress
        TEXT created_at
        TEXT updated_at
        TEXT notes
    }

    trip_transport {
        VARCHAR trip_id PK,FK
        VARCHAR transport_type PK
    }

    trip_activities {
        INTEGER id PK
        VARCHAR trip_id FK
        VARCHAR activity
    }

    packing_lists {
        VARCHAR id PK
        VARCHAR trip_id FK
        VARCHAR user_id FK
        VARCHAR name
        TEXT created_at
        TEXT updated_at
    }

    packing_items {
        VARCHAR id PK
        VARCHAR list_id FK
        VARCHAR trip_id FK
        VARCHAR user_id FK
        VARCHAR name
        VARCHAR category
        INTEGER is_packed
        INTEGER is_auto_generated
        INTEGER quantity
        INTEGER order_index
        TEXT notes
        TEXT created_at
        TEXT updated_at
    }

    chats {
        VARCHAR id PK
        VARCHAR type
        VARCHAR name
        TEXT created_at
    }

    chat_members {
        VARCHAR chat_id PK,FK
        VARCHAR user_id PK,FK
        TEXT joined_at
    }

    messages {
        VARCHAR id PK
        VARCHAR chat_id FK
        VARCHAR sender_id FK
        TEXT text
        TEXT created_at
        INTEGER is_read
    }

    user_sessions {
        VARCHAR id PK
        VARCHAR user_id FK
        VARCHAR token
        TEXT device_info
        TEXT created_at
        TEXT expires_at
    }
```

## Descripcion de Tablas

| Tabla | Descripcion |
|-------|-------------|
| **users** | Usuarios registrados (email/password o Google). Plan free/premium. |
| **trips** | Viajes creados por cada usuario. Fechas, destino, progreso. |
| **trip_transport** | Transportes asociados a un viaje (relacion N:M). |
| **trip_activities** | Actividades planificadas para un viaje. |
| **packing_lists** | Listas de equipaje asociadas a un viaje. |
| **packing_items** | Items individuales dentro de una lista de equipaje. |
| **chats** | Conversaciones (soporte, IA, grupo). |
| **chat_members** | Miembros de cada chat (relacion N:M). |
| **messages** | Mensajes dentro de un chat. |
| **user_sessions** | Sesiones activas para seguridad. |

## Indices

- `idx_users_email` en users(email)
- `idx_trips_user_id` en trips(user_id)
- `idx_trips_dates` en trips(start_date, end_date)
- `idx_activities_trip` en trip_activities(trip_id)
- `idx_lists_trip` en packing_lists(trip_id)
- `idx_items_list` en packing_items(list_id)
- `idx_items_category` en packing_items(category)
- `idx_messages_chat` en messages(chat_id)
- `idx_sessions_token` en user_sessions(token)

## Triggers

- `update_trips_timestamp` - Actualiza updated_at en trips
- `update_lists_timestamp` - Actualiza updated_at en packing_lists
- `update_items_timestamp` - Actualiza updated_at en packing_items
