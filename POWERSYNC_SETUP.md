# Configuration PowerSync pour AuditFlow

## Prérequis

### 1. PostgreSQL Configuration

Vérifiez que PostgreSQL est configuré pour la réplication logique :

```sql
-- Vérifier la configuration actuelle
SHOW wal_level;        -- Doit être 'logical'
SHOW max_replication_slots;
SHOW max_wal_senders;

-- Si nécessaire, modifiez postgresql.conf :
-- wal_level = logical
-- max_replication_slots = 10
-- max_wal_senders = 10
```

### 2. Installation Dépendances

#### Backend
```bash
cd backend
npm install
```

#### Frontend Flutter
```bash
cd ..
flutter pub get
```

## Configuration PowerSync Cloud

### 1. Créer un compte
- Allez sur https://www.powersync.com
- Créez un compte gratuit
- Créez un nouveau projet "AuditFlow"

### 2. Connecter PostgreSQL
Dans PowerSync Dashboard :
- Database URL : `postgresql://user:pass@host:port/auditflow`
- SSL Mode : require (production) / prefer (dev)

### 3. Upload Sync Rules
Dans PowerSync Dashboard > Sync Rules, collez :

```yaml
bucket_definitions:
  global_templates:
    data:
      - SELECT * FROM templates WHERE is_public = true
      - SELECT q.* FROM questions q
        JOIN templates t ON q.template_id = t.id
        WHERE t.is_public = true

  user_data:
    parameters: user_id
    data:
      - SELECT * FROM templates WHERE user_id = bucket.user_id
      - SELECT q.* FROM questions q
        JOIN templates t ON q.template_id = t.id
        WHERE t.user_id = bucket.user_id
      - SELECT * FROM audits WHERE user_id = bucket.user_id
      - SELECT a.* FROM answers a
        JOIN audits au ON a.audit_id = au.id
        WHERE au.user_id = bucket.user_id
```

### 4. Configuration Client Flutter

Dans `lib/powersync/service.dart`, mettez à jour l'endpoint :

```dart
final powerSyncEndpoint = 'wss://votre-instance.powersync.com';
```

Et l'URL de l'API backend :

```dart
Uri.parse('https://votre-api.com/powersync/upload'),
```

## Configuration Alternative (Self-Hosted)

Si vous préférez héberger PowerSync vous-même :

```yaml
# docker-compose.yml
version: '3.8'
services:
  powersync:
    image: journeyapps/powersync-service:latest
    environment:
      - PORT=8080
      - DATABASE_URL=postgresql://user:pass@postgres:5432/auditflow
      - DATABASE_SSL=false
      - POWERSYNC_PUBLIC_KEY=your-public-key
    ports:
      - "8080:8080"
```

## Initialisation dans l'App

### 1. Au démarrage de l'app (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser PowerSync
  await PowerSyncService().initialize();
  
  runApp(MyApp());
}
```

### 2. Après connexion utilisateur

```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isAuthenticated) {
          // Connecter PowerSync
          PowerSyncService().connect(
            userId: auth.userId,
            authToken: auth.token,
          );
          return HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}
```

### 3. Utilisation dans les screens

```dart
class AuditsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PowerSyncService().watchAudits(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final audits = snapshot.data!;
          return ListView.builder(
            itemCount: audits.length,
            itemBuilder: (context, index) {
              return AuditCard(audit: audits[index]);
            },
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## Migration depuis API REST

### Avant (API REST)
```dart
// Service API
final audits = await apiService.getAudits();

// UI
setState(() => _audits = audits);
```

### Après (PowerSync)
```dart
// Service PowerSync - données locales
final audits = await PowerSyncService().getAudits();

// UI réactive - auto-update
PowerSyncService().watchAudits().listen((audits) {
  setState(() => _audits = audits);
});
```

## Dépannage

### Erreur "wal_level is not logical"
```sql
-- Modifier postgresql.conf
wal_level = logical

-- Redémarrer PostgreSQL
```

### Sync ne démarre pas
Vérifiez :
- Endpoint PowerSync correct
- Token JWT valide
- Connexion internet

### Données non synchronisées
Vérifiez :
- Sync Rules correctement uploadées
- Tables dans le schéma PowerSync
- Logs backend (`/powersync/upload`)

## Sécurité

- Utilisez HTTPS/WSS en production
- Validez tous les changements côté backend
- Limitez les données par utilisateur dans sync rules
- Paginez les gros ensembles de données
