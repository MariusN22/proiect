# Sistem de Monitorizare, Suport și Siguranță pentru Persoane în Vârstă

Aplicație mobilă dedicată monitorizării persoanelor în vârstă, care oferă funcționalități de urmărire în timp real a stării de sănătate, gestionarea relației pacient-medic și alertare în cazuri critice.

## 📱 Tehnologii utilizate

- **Flutter** – interfață mobilă (Android)
- **Firebase** – autentificare, bază de date realtime, stocare documente
- **Senzori** – puls și temperatură integrați în dispozitiv
- **Firebase Storage** – pentru încărcarea actelor de identitate și a documentelor medicale

## ⚙️ Funcționalități implementate

### ✅ Aplicație pacient:
- Înregistrare cu act de identitate
- Alegere medic (din lista aprobată)
- Afișare grafică a datelor de la senzori
- Pagina de profil (cu poză salvată în Firebase)
- Meniu lateral cu acces rapid la funcții

### ✅ Aplicație medic:
- Înregistrare cu documente medicale
- Aprobare cont de către admin (din Firebase)
- Vizualizare lista pacienți
- Acces la datele medicale în timp real
- Profil personalizat

### 🔧 În curs de implementare:
- Detecție cădere cu accelerometru
- Alarme configurabile în aplicație
- Secțiune recomandări (medicamente, repaus)
- Roluri multiple (rude/îngrijitori cu acces la datele pacientului)



