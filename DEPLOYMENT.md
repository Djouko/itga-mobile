# ITGA Mobile Deployment

Ce depot contient l'application Flutter Android et iOS.

Regle importante: aucun secret reel ne doit etre commite dans Git. Les fichiers Firebase, les cles Android et les identifiants Apple doivent rester en local ou dans les variables securisees de Codemagic.

## 0. Tu es deja sur Codemagic: quoi faire maintenant

Sur ta capture, tu es dans l'ecran de configuration visuelle `Default Workflow`. Pour ITGA, il ne faut pas continuer avec ce workflow visuel, parce que le depot contient deja un fichier `codemagic.yaml` prepare pour iOS. Il faut basculer sur la configuration YAML.

### Etape 0.1: passer du workflow visuel au YAML

1. Reste sur l'application Codemagic `itga-mobile`.
2. Regarde en haut a droite de l'ecran.
3. Clique sur `Switch to YAML configuration`.
4. Si Codemagic demande confirmation, confirme.
5. Si Codemagic demande le chemin du fichier YAML, ecris exactement:

```text
codemagic.yaml
```

6. Enregistre.
7. Reviens sur la page de l'application si Codemagic te redirige.
8. Clique sur `Start new build`.
9. Dans `Branch`, choisis `main`.
10. Tu dois maintenant voir les workflows du fichier YAML:

```text
ITGA iOS test build without signing
ITGA iOS signed IPA for TestFlight
```

Si tu vois encore seulement `Default Workflow`, c'est que Codemagic n'utilise pas encore le YAML. Dans ce cas, ne lance pas le build. Reviens dans les settings et verifie que la configuration est bien `codemagic.yaml`.

### Etape 0.2: creer le groupe de variables securisees

Le fichier `codemagic.yaml` importe un groupe de variables qui s'appelle exactement:

```text
itga_mobile
```

Dans Codemagic:

1. Ouvre l'application `itga-mobile`.
2. Va dans `Environment variables`.
3. Clique pour creer un nouveau groupe si Codemagic le demande.
4. Nom du groupe: `itga_mobile`
5. Attention: respecte exactement les minuscules et le tiret bas.
6. Dans ce groupe, ajoute les variables de l'etape suivante.

### Etape 0.3: ajouter les 3 variables obligatoires

Dans le groupe `itga_mobile`, ajoute:

```env
ITGA_API_KEY=valeur-reelle-de-la-cle-api-backend
FIREBASE_IOS_PLIST_B64=contenu-base64-du-fichier-ios
FIREBASE_ANDROID_JSON_B64=contenu-base64-du-fichier-android
```

Pour chaque variable:

1. Clique `Add variable`.
2. Mets le nom exactement comme ci-dessus.
3. Colle la valeur.
4. Coche `Secure` ou `Secret`.
5. Enregistre.

Ne mets pas de guillemets autour des valeurs. Ne laisse pas d'espace avant ou apres.

### Etape 0.4: comment obtenir `FIREBASE_IOS_PLIST_B64`

Sur ton ordinateur Windows, ouvre PowerShell:

```powershell
cd "F:\Workspace\Freelance\IT Girls\Code\chatter\19 decembre\Chatter 19 December 2025\ITGA\chatter_flutter\chatter"
Test-Path ios\Runner\GoogleService-Info.plist
```

Si PowerShell affiche `True`, copie la valeur base64:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios\Runner\GoogleService-Info.plist")) | Set-Clipboard
```

Ensuite retourne dans Codemagic et colle dans `FIREBASE_IOS_PLIST_B64`.

Si PowerShell affiche `False`, tu dois aller dans Firebase Console, ouvrir le projet ITGA, ajouter/ouvrir l'app iOS avec bundle id `com.retrytech.chatter`, telecharger `GoogleService-Info.plist`, puis le placer ici:

```text
chatter_flutter/chatter/ios/Runner/GoogleService-Info.plist
```

### Etape 0.5: comment obtenir `FIREBASE_ANDROID_JSON_B64`

Dans PowerShell:

```powershell
cd "F:\Workspace\Freelance\IT Girls\Code\chatter\19 decembre\Chatter 19 December 2025\ITGA\chatter_flutter\chatter"
Test-Path android\app\google-services.json
```

Si PowerShell affiche `True`, copie la valeur base64:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\google-services.json")) | Set-Clipboard
```

Ensuite retourne dans Codemagic et colle dans `FIREBASE_ANDROID_JSON_B64`.

### Etape 0.6: lancer le premier build iOS sans signature

Ne commence pas par TestFlight. Commence par verifier que l'app compile sur iOS.

1. Dans Codemagic, clique `Start new build`.
2. Branch: `main`.
3. Workflow: `ITGA iOS test build without signing`.
4. Clique `Start new build`.
5. Attends la fin.

Resultat attendu: le build doit finir en vert.

Si le build echoue:

- Clique sur l'etape rouge.
- Lis le message exact.
- Si le message parle de `ITGA_API_KEY`, `FIREBASE_IOS_PLIST_B64` ou `FIREBASE_ANDROID_JSON_B64`, corrige les variables.
- Si le message parle de `GoogleService-Info.plist`, verifie que le fichier iOS vient bien de Firebase pour `com.retrytech.chatter`.
- Si le message parle de `pod install`, relance une fois; si ca continue, il faut corriger les pods.

### Etape 0.7: seulement apres le build vert, preparer TestFlight

Pour TestFlight, il faut un compte Apple Developer payant. Sans ca, tu peux faire le test sans signature, mais pas distribuer proprement aux iPhones.

Quand le compte Apple Developer est disponible:

1. Cree l'app id iOS `com.retrytech.chatter` dans Apple Developer.
2. Cree l'app ITGA dans App Store Connect avec le meme bundle id.
3. Connecte Apple Developer/App Store Connect a Codemagic.
4. Verifie que Codemagic trouve un certificat de distribution.
5. Verifie que Codemagic trouve un provisioning profile App Store.
6. Lance le workflow `ITGA iOS signed IPA for TestFlight`.

Resultat attendu:

```text
build/ios/ipa/*.ipa
```

### Etape 0.8: envoyer aux testeurs iPhone

Une fois le build signe reussi:

1. Ouvre App Store Connect.
2. Va dans `My Apps`.
3. Ouvre ITGA.
4. Va dans `TestFlight`.
5. Attends que le build soit traite par Apple.
6. Ajoute ton adresse email comme testeur interne.
7. Installe l'application `TestFlight` sur ton iPhone.
8. Accepte l'invitation recue par email.
9. Installe ITGA depuis TestFlight.
10. Teste connexion, creation de compte, feed, rooms, jobs, profil entreprise, notifications et appel video.

## 1. Fichiers locaux obligatoires

Ces fichiers sont volontairement ignores par Git:

```text
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
android/local.properties
android/key.properties
```

Avant un build local, verifier qu'ils existent:

```powershell
cd "F:\Workspace\Freelance\IT Girls\Code\chatter\19 decembre\Chatter 19 December 2025\ITGA\chatter_flutter\chatter"
Test-Path android\app\google-services.json
Test-Path ios\Runner\GoogleService-Info.plist
```

Chaque commande doit afficher `True`. Si une commande affiche `False`, recuperer le fichier correspondant depuis Firebase avant de builder.

## 2. Variable obligatoire pour tous les builds

Chaque build public doit recevoir la meme cle API publique que le backend attend pour les clients mobiles/web:

```text
--dart-define=ITGA_API_KEY=remplacer-par-la-valeur-backend-API_SECRET_KEY
```

Ne pas mettre la valeur dans ce fichier. La valeur reelle doit rester dans les secrets locaux ou dans Codemagic.

## 3. Android local

Depuis le dossier `chatter_flutter/chatter`:

```powershell
flutter pub get
flutter test --no-pub
flutter build apk --release --dart-define=ITGA_API_KEY=remplacer-par-la-cle-reelle
flutter build appbundle --release --dart-define=ITGA_API_KEY=remplacer-par-la-cle-reelle
```

Chemins attendus apres build:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

Pour Google Play Store, utiliser le fichier `.aab`.
Pour partager une installation directe a un testeur Android, utiliser le fichier `.apk`.

## 4. Signature Android

Le fichier `android/key.properties` doit rester local et doit contenir:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=...
```

Si `android/key.properties` manque, Gradle peut tomber sur une signature de debug pour certains tests locaux. Ne jamais envoyer un AAB signe en debug sur Google Play.

## 5. iOS: verite importante avant Codemagic

Pour installer l'application sur des iPhones de vrais utilisateurs via TestFlight ou App Store, il faut obligatoirement un compte Apple Developer payant.

Sans compte Apple Developer payant:

- Codemagic peut verifier que le projet iOS compile avec `ios-test-no-codesign`.
- Codemagic ne peut pas publier proprement une application pour le public.
- On ne peut pas distribuer une vraie application iOS publique comme un APK Android.

Objectif minimum realiste:

1. Lancer `ios-test-no-codesign` pour verifier que le code iOS est sain.
2. Des que le compte Apple Developer est disponible, configurer la signature.
3. Lancer `ios-testflight-signed` pour obtenir un IPA signe.
4. Envoyer cet IPA vers TestFlight/App Store Connect.

## 6. iOS: bundle identifier a respecter

Le projet iOS utilise actuellement ce bundle identifier:

```text
com.retrytech.chatter
```

Il doit etre identique partout:

- `ios/Runner.xcodeproj/project.pbxproj`
- Apple Developer portal, section Identifiers
- App Store Connect, fiche de l'application
- Firebase iOS app, fichier `GoogleService-Info.plist`
- `codemagic.yaml`, champ `bundle_identifier`

Si un seul endroit utilise un autre identifiant, Google Sign-In, Firebase, la signature iOS ou TestFlight peuvent echouer.

## 7. iOS: preparer Firebase pour Codemagic

Codemagic ne doit pas recevoir les fichiers Firebase en clair dans Git. Il faut les encoder en base64 puis les coller dans des variables securisees.

Depuis PowerShell:

```powershell
cd "F:\Workspace\Freelance\IT Girls\Code\chatter\19 decembre\Chatter 19 December 2025\ITGA\chatter_flutter\chatter"
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios\Runner\GoogleService-Info.plist")) | Set-Clipboard
```

Dans Codemagic:

1. Ouvrir l'application ITGA mobile.
2. Aller dans `Environment variables`.
3. Ajouter une variable.
4. Nom: `FIREBASE_IOS_PLIST_B64`
5. Valeur: coller ce qui est dans le presse-papiers.
6. Cocher `Secure`.
7. Enregistrer.

Ensuite refaire la meme chose pour Android:

```powershell
cd "F:\Workspace\Freelance\IT Girls\Code\chatter\19 decembre\Chatter 19 December 2025\ITGA\chatter_flutter\chatter"
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\google-services.json")) | Set-Clipboard
```

Dans Codemagic:

1. Ajouter une variable.
2. Nom: `FIREBASE_ANDROID_JSON_B64`
3. Valeur: coller ce qui est dans le presse-papiers.
4. Cocher `Secure`.
5. Enregistrer.

## 8. iOS: variables Codemagic obligatoires

Dans Codemagic, creer ces variables securisees:

```env
ITGA_API_KEY=valeur-reelle-du-backend-API_SECRET_KEY
FIREBASE_IOS_PLIST_B64=base64-du-fichier-ios
FIREBASE_ANDROID_JSON_B64=base64-du-fichier-android
```

Controle avant de lancer un build:

- Les trois variables existent.
- Les trois variables sont marquees `Secure`.
- Aucune valeur n'est vide.
- Aucune valeur ne contient de guillemets autour.
- `ITGA_API_KEY` est exactement la meme valeur que celle attendue par le backend.

## 9. iOS: branch GitHub et workflow Codemagic

Le depot GitHub attendu pour le mobile est:

```text
https://github.com/Djouko/itga-mobile.git
```

Dans Codemagic:

1. Cliquer `Add application`.
2. Choisir GitHub.
3. Choisir le depot `Djouko/itga-mobile`.
4. Choisir la branche `main`.
5. Choisir la configuration `codemagic.yaml`.
6. Verifier que Codemagic detecte les workflows:
   - `ITGA iOS test build without signing`
   - `ITGA iOS signed IPA for TestFlight`

## 10. iOS: premier test sans signature

Toujours commencer par ce workflow:

```text
ios-test-no-codesign
```

Ce workflow fait:

1. Verification de `ITGA_API_KEY`.
2. Restauration de `GoogleService-Info.plist`.
3. Restauration de `google-services.json`.
4. `flutter pub get`.
5. `flutter analyze --no-pub --no-fatal-infos`.
6. `flutter test --no-pub`.
7. `pod install`.
8. `flutter build ios --release --no-codesign`.

Resultat attendu:

```text
build/ios/iphoneos/*.app
```

Si ce workflow echoue, ne pas lancer le workflow signe. Corriger d'abord l'erreur.

Erreurs frequentes:

- `ITGA_API_KEY is required`: la variable manque dans Codemagic.
- `FIREBASE_IOS_PLIST_B64 is required`: la variable Firebase iOS manque.
- `GoogleService-Info.plist was not restored`: la valeur base64 est vide ou mal collee.
- Erreur CocoaPods: relancer le build une fois; si cela continue, verifier les pods iOS.
- Erreur Firebase iOS: verifier que le fichier `GoogleService-Info.plist` correspond au bundle id `com.retrytech.chatter`.

## 11. iOS: preparer la signature Apple

Cette partie demande un compte Apple Developer payant.

Dans Apple Developer:

1. Ouvrir le compte Apple Developer.
2. Aller dans `Certificates, Identifiers & Profiles`.
3. Creer ou verifier l'identifiant d'app:
   - Type: App IDs
   - Platform: iOS
   - Bundle ID: `com.retrytech.chatter`
4. Activer les capacites necessaires:
   - Push Notifications si l'app utilise les notifications push.
   - Sign in with Apple si l'app l'utilise maintenant ou plus tard.
5. Creer le certificat de distribution iOS.
6. Creer le provisioning profile App Store pour `com.retrytech.chatter`.

Dans App Store Connect:

1. Aller dans `My Apps`.
2. Creer une nouvelle app si elle n'existe pas.
3. Platform: iOS.
4. Name: ITGA.
5. Bundle ID: `com.retrytech.chatter`.
6. SKU: choisir une valeur simple, par exemple `itga-ios`.
7. Donner acces au compte qui va publier.

## 12. iOS: configurer la signature dans Codemagic

Dans Codemagic, utiliser la signature iOS automatique ou connecter App Store Connect selon l'interface disponible.

Checklist minimale:

- Codemagic peut acceder au compte Apple Developer.
- Le bundle identifier est `com.retrytech.chatter`.
- Le certificat de distribution est disponible.
- Le provisioning profile App Store est disponible.
- La configuration correspond au workflow `ios-testflight-signed`.

Le fichier `codemagic.yaml` contient deja:

```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: com.retrytech.chatter
```

Cela indique a Codemagic de preparer une signature App Store pour ce bundle id.

## 13. iOS: build signe pour TestFlight

Quand la signature est prete, lancer:

```text
ios-testflight-signed
```

Ce workflow fait:

1. Verification de `ITGA_API_KEY`.
2. Restauration des fichiers Firebase.
3. Installation des dependances Flutter.
4. Analyse Flutter.
5. Tests Flutter.
6. `pod install`.
7. `xcode-project use-profiles`.
8. `flutter build ipa --release`.

Resultats attendus:

```text
build/ios/ipa/*.ipa
build/ios/archive/*.xcarchive
```

Si le workflow echoue sur `xcode-project use-profiles`, le probleme est presque toujours la signature Apple: certificat, profile, bundle id ou connexion Apple Developer.

## 14. iOS: envoyer vers TestFlight

Option A: depuis Codemagic si App Store Connect publishing est configure.

1. Configurer l'integration App Store Connect dans Codemagic.
2. Ajouter la section de publication dans `codemagic.yaml` seulement quand l'integration fonctionne.
3. Relancer le workflow signe.

Option B: manuellement si on veut aller vite.

1. Telecharger le fichier `.ipa` depuis les artifacts Codemagic.
2. Sur un Mac, ouvrir l'application Apple Transporter.
3. Se connecter avec le compte App Store Connect.
4. Glisser le fichier `.ipa`.
5. Cliquer `Deliver`.
6. Attendre que le build apparaisse dans App Store Connect > TestFlight.

Sans Mac disponible, privilegier l'option A avec Codemagic.

## 15. iOS: tests TestFlight obligatoires avant public

Installer l'application via TestFlight sur au moins un iPhone reel.

Verifier:

1. Ouverture de l'app sans crash.
2. Connexion utilisateur email.
3. Connexion entreprise email.
4. Connexion Google si activee pour iOS.
5. Creation de compte utilisateur.
6. Creation de compte entreprise.
7. Feed: chargement, publication texte, photo, video/audio si active.
8. Rooms: suggestions, affichage, entree dans une room.
9. Jobs: liste, details, candidature, mode clair actuel.
10. Profil utilisateur: affichage, photo, mentions cliquables.
11. Profil entreprise: affichage, offres, posts.
12. Notifications in-app.
13. Push notifications Firebase sur iPhone reel.
14. Appels audio/video: permission micro, permission camera, connexion Agora.
15. Reprise apres mise en arriere-plan.
16. Deconnexion/reconnexion.

Si une seule verification critique echoue, ne pas ouvrir au public iOS.

## 16. iOS: push notifications

Pour les push iOS, il faut aussi configurer Firebase Cloud Messaging cote iOS.

Verifier:

- Le bundle id Firebase iOS est `com.retrytech.chatter`.
- Le fichier `GoogleService-Info.plist` vient de cette app Firebase iOS.
- Les certificats/APNs sont configures dans Firebase.
- L'app demande la permission de notification sur iPhone.
- Un token FCM est bien genere sur iPhone.
- Le backend enregistre ce token.

Test manuel:

1. Installer l'app TestFlight sur l'iPhone.
2. Se connecter.
3. Accepter les notifications.
4. Depuis Firebase Console ou le backend, envoyer une notification test.
5. Verifier que la notification arrive quand l'app est ouverte, en arriere-plan, puis fermee.

## 17. Sources officielles utiles

- Codemagic Flutter projects: https://docs.codemagic.io/flutter-configuration/flutter-projects/
- Codemagic iOS code signing: https://docs.codemagic.io/yaml-code-signing/signing-ios/
- Codemagic App Store Connect publishing: https://docs.codemagic.io/yaml-publishing/app-store-connect/
- Codemagic YAML getting started: https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/
