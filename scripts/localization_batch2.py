"""French, German, Spanish, and Polish translations (batch 2)."""

from __future__ import annotations

BATCH2_LANGS = ("fr", "de", "es", "pl")

BATCH2: dict[str, dict[str, str]] = {
    "filter.all": {"fr": "Tous les types", "de": "Alle Typen", "es": "Todos los tipos", "pl": "Wszystkie typy"},
    "filter.text": {"fr": "Texte", "de": "Text", "es": "Texto", "pl": "Tekst"},
    "filter.number": {"fr": "Nombre", "de": "Zahl", "es": "Número", "pl": "Liczba"},
    "filter.link": {"fr": "Lien", "de": "Link", "es": "Enlace", "pl": "Link"},
    "filter.image": {"fr": "Image", "de": "Bild", "es": "Imagen", "pl": "Obraz"},
    "filter.file": {"fr": "Fichier", "de": "Datei", "es": "Archivo", "pl": "Plik"},
    "filter.byType": {"fr": "Filtrer par type", "de": "Nach Typ filtern", "es": "Filtrar por tipo", "pl": "Filtruj według typu"},
    "filter.clear": {"fr": "Effacer le filtre de type", "de": "Typfilter löschen", "es": "Borrar filtro de tipo", "pl": "Wyczyść filtr typu"},
    "tab.default": {"fr": "Par défaut", "de": "Standard", "es": "Predeterminado", "pl": "Domyślne"},
    "tab.pinned": {"fr": "Épinglés", "de": "Angeheftet", "es": "Fijados", "pl": "Przypięte"},
    "tab.folder": {"fr": "Dossier", "de": "Ordner", "es": "Carpeta", "pl": "Folder"},
    "clipType.text": {"fr": "Texte", "de": "Text", "es": "Texto", "pl": "Tekst"},
    "clipType.richText": {"fr": "Texte enrichi", "de": "Rich Text", "es": "Texto enriquecido", "pl": "Tekst sformatowany"},
    "clipType.html": {"fr": "HTML", "de": "HTML", "es": "HTML", "pl": "HTML"},
    "clipType.image": {"fr": "Image", "de": "Bild", "es": "Imagen", "pl": "Obraz"},
    "clipType.file": {"fr": "Fichier", "de": "Datei", "es": "Archivo", "pl": "Plik"},
    "clipType.url": {"fr": "Lien", "de": "Link", "es": "Enlace", "pl": "Link"},
    "clipType.mixed": {"fr": "Mixte", "de": "Gemischt", "es": "Mixto", "pl": "Mieszany"},
    "clipType.folder": {"fr": "Dossier", "de": "Ordner", "es": "Carpeta", "pl": "Folder"},
    "clipType.empty": {"fr": "Vide", "de": "Leer", "es": "Vacío", "pl": "Pusto"},
    "clipPreview.oneCharacter": {"fr": "1 caractère", "de": "1 Zeichen", "es": "1 carácter", "pl": "1 znak"},
    "clipPreview.characters": {"fr": "%lld caractères", "de": "%lld Zeichen", "es": "%lld caracteres", "pl": "%lld znaków"},
    "keepHistory.oneDay": {"fr": "1 jour", "de": "1 Tag", "es": "1 día", "pl": "1 dzień"},
    "keepHistory.oneWeek": {"fr": "1 semaine", "de": "1 Woche", "es": "1 semana", "pl": "1 tydzień"},
    "keepHistory.oneMonth": {"fr": "1 mois", "de": "1 Monat", "es": "1 mes", "pl": "1 miesiąc"},
    "keepHistory.forever": {"fr": "Pour toujours", "de": "Für immer", "es": "Para siempre", "pl": "Na zawsze"},
    "stack.fifo": {"fr": "Premier entré, premier sorti", "de": "Zuerst rein, zuerst raus", "es": "Primero en entrar, primero en salir", "pl": "Pierwsze weszło, pierwsze wyszło"},
    "stack.lifo": {"fr": "Dernier entré, premier sorti", "de": "Zuletzt rein, zuerst raus", "es": "Último en entrar, primero en salir", "pl": "Ostatnie weszło, pierwsze wyszło"},
    "stack.fifoHelp": {
        "fr": "Ordre de copie. Cliquez pour inverser.",
        "de": "Kopierreihenfolge. Klicken zum Umkehren.",
        "es": "Orden de copia. Haz clic para invertir.",
        "pl": "Kolejność kopiowania. Kliknij, aby odwrócić.",
    },
    "stack.lifoHelp": {
        "fr": "Le plus récent d'abord. Cliquez pour l'ordre de copie.",
        "de": "Neueste zuerst. Klicken für Kopierreihenfolge.",
        "es": "Lo más reciente primero. Haz clic para orden de copia.",
        "pl": "Najnowsze najpierw. Kliknij dla kolejności kopiowania.",
    },
    "stack.paste": {"fr": "Coller", "de": "Einfügen", "es": "Pegar", "pl": "Wklej"},
    "stack.open": {"fr": "Ouvrir la pile de collage", "de": "Einfügestapel öffnen", "es": "Abrir pila de pegado", "pl": "Otwórz stos wklejania"},
    "stack.close": {"fr": "Fermer la pile de collage", "de": "Einfügestapel schließen", "es": "Cerrar pila de pegado", "pl": "Zamknij stos wklejania"},
    "stack.title": {"fr": "Pile", "de": "Stapel", "es": "Pila", "pl": "Stos"},
    "stack.statusWithCount": {"fr": "Pile · %lld", "de": "Stapel · %lld", "es": "Pila · %lld", "pl": "Stos · %lld"},
    "stack.collecting": {"fr": "Collecte", "de": "Sammeln", "es": "Recopilando", "pl": "Zbieranie"},
    "stack.closeHelp": {"fr": "Fermer la pile de collage (⇧⌘C)", "de": "Einfügestapel schließen (⇧⌘C)", "es": "Cerrar pila de pegado (⇧⌘C)", "pl": "Zamknij stos wklejania (⇧⌘C)"},
    "stack.pasteNext": {"fr": "⌘V colle le suivant", "de": "⌘V fügt das Nächste ein", "es": "⌘V pega el siguiente", "pl": "⌘V wkleja następny"},
    "stack.emptyTitle": {"fr": "Copiez pour remplir la pile", "de": "Kopieren, um den Stapel zu füllen", "es": "Copia para llenar la pila", "pl": "Kopiuj, aby wypełnić stos"},
    "stack.emptySubtitle": {"fr": "Puis ⌘V dans n'importe quelle app", "de": "Dann ⌘V in einer beliebigen App", "es": "Luego ⌘V en cualquier app", "pl": "Potem ⌘V w dowolnej aplikacji"},
    "stack.accessibilityHint": {
        "fr": "Autorisez l'accessibilité pour que ⌘V fasse avancer la pile",
        "de": "Bedienungshilfen erlauben, damit ⌘V den Stapel voranbringt",
        "es": "Concede accesibilidad para que ⌘V avance la pila",
        "pl": "Zezwól na dostępność, aby ⌘V przechodziło do następnego",
    },
    "stack.resizeHelp": {"fr": "Glisser pour redimensionner la hauteur", "de": "Ziehen, um die Höhe zu ändern", "es": "Arrastra para cambiar la altura", "pl": "Przeciągnij, aby zmienić wysokość"},
    "stack.moveToNext": {"fr": "Passer au suivant", "de": "Zum Nächsten", "es": "Mover al siguiente", "pl": "Przenieś do następnego"},
    "stack.delete": {"fr": "Supprimer", "de": "Löschen", "es": "Eliminar", "pl": "Usuń"},
    "menu.openPaste": {"fr": "Ouvrir l'historique", "de": "Verlauf öffnen", "es": "Abrir historial", "pl": "Otwórz historię"},
    "menu.clearStack": {"fr": "Vider la pile de collage", "de": "Einfügestapel leeren", "es": "Vaciar pila de pegado", "pl": "Wyczyść stos wklejania"},
    "menu.pastePlain": {"fr": "Coller sans mise en forme", "de": "Als Text einfügen", "es": "Pegar sin formato", "pl": "Wklej bez formatowania"},
    "menu.pauseCapture": {"fr": "Suspendre la capture", "de": "Erfassung pausieren", "es": "Pausar captura", "pl": "Wstrzymaj przechwytywanie"},
    "menu.resumeCapture": {"fr": "Reprendre la capture", "de": "Erfassung fortsetzen", "es": "Reanudar captura", "pl": "Wznów przechwytywanie"},
    "menu.mcp": {"fr": "MCP", "de": "MCP", "es": "MCP", "pl": "MCP"},
    "menu.copyMcpURL": {"fr": "Copier l'URL MCP", "de": "MCP-URL kopieren", "es": "Copiar URL de MCP", "pl": "Kopiuj adres URL MCP"},
    "menu.preferences": {"fr": "Réglages…", "de": "Einstellungen…", "es": "Preferencias…", "pl": "Ustawienia…"},
    "menu.checkUpdates": {"fr": "Rechercher des mises à jour…", "de": "Nach Updates suchen…", "es": "Buscar actualizaciones…", "pl": "Sprawdź aktualizacje…"},
    "menu.quit": {"fr": "Quitter Pastel it！", "de": "Pastel it！ beenden", "es": "Salir de Pastel it！", "pl": "Zakończ Pastel it！"},
    "menu.more": {"fr": "Plus", "de": "Mehr", "es": "Más", "pl": "Więcej"},
    "menu.statusTooltip": {
        "fr": "Pastel it！ — maintenez ⌘C / ⌘V pour afficher les touches",
        "de": "Pastel it！ — ⌘C / ⌘V gedrückt halten, um die Tasten anzuzeigen",
        "es": "Pastel it！ — mantén ⌘C / ⌘V para ver las teclas",
        "pl": "Pastel it！ — przytrzymaj ⌘C / ⌘V, aby pokazać klawisze",
    },
    "menu.statusClickHint": {
        "fr": "Clic gauche : historique · Clic droit : menu",
        "de": "Linksklick: Verlauf · Rechtsklick: Menü",
        "es": "Clic izquierdo: historial · Clic derecho: menú",
        "pl": "Lewy przycisk: historia · Prawy przycisk: menu",
    },
    "timeline.clearFilter": {"fr": "Effacer le filtre", "de": "Filter löschen", "es": "Borrar filtro", "pl": "Wyczyść filtr"},
    "timeline.selectedCount": {
        "fr": "%lld sélectionnés — Entrée pour coller",
        "de": "%lld ausgewählt — Eingabe zum Einfügen",
        "es": "%lld seleccionados — Intro para pegar",
        "pl": "Wybrano %lld — Return, aby wkleić",
    },
    "timeline.newFolder": {"fr": "Nouveau dossier", "de": "Neuer Ordner", "es": "Nueva carpeta", "pl": "Nowy folder"},
    "timeline.newFolderHelp": {"fr": "Nouveau dossier", "de": "Neuer Ordner", "es": "Nueva carpeta", "pl": "Nowy folder"},
    "timeline.search": {"fr": "Rechercher (⌘F)", "de": "Suchen (⌘F)", "es": "Buscar (⌘F)", "pl": "Szukaj (⌘F)"},
    "timeline.searchHistory": {"fr": "Rechercher dans l'historique", "de": "Verlauf durchsuchen", "es": "Buscar en el historial", "pl": "Przeszukaj historię"},
    "timeline.noMatch": {"fr": "Aucun élément correspondant", "de": "Keine passenden Einträge", "es": "No hay elementos coincidentes", "pl": "Brak pasujących elementów"},
    "timeline.noTypeInPinned": {
        "fr": "Aucun élément %@ dans Épinglés",
        "de": "Keine %@-Einträge in Angeheftet",
        "es": "No hay elementos %@ en Fijados",
        "pl": "Brak elementów %@ w Przypięte",
    },
    "timeline.noTypeInFolder": {
        "fr": "Aucun élément %@ dans ce dossier",
        "de": "Keine %@-Einträge in diesem Ordner",
        "es": "No hay elementos %@ en esta carpeta",
        "pl": "Brak elementów %@ w tym folderze",
    },
    "timeline.noType": {
        "fr": "Aucun élément %@",
        "de": "Keine %@-Einträge",
        "es": "No hay elementos %@",
        "pl": "Brak elementów %@",
    },
    "timeline.emptyDefault": {
        "fr": "Copiez quelque chose pour créer votre historique",
        "de": "Kopieren Sie etwas, um Ihren Verlauf aufzubauen",
        "es": "Copia algo para crear tu historial",
        "pl": "Skopiuj coś, aby zbudować historię schowka",
    },
    "timeline.emptyPinned": {
        "fr": "Épinglez des éléments pour les garder ici",
        "de": "Einträge anheften, um sie hier zu behalten",
        "es": "Fija elementos para conservarlos aquí",
        "pl": "Przypnij elementy, aby zachować je tutaj",
    },
    "timeline.emptyFolder": {
        "fr": "Ajoutez des éléments à ce dossier depuis le menu contextuel",
        "de": "Einträge über das Kontextmenü zu diesem Ordner hinzufügen",
        "es": "Añade elementos a esta carpeta desde el menú contextual",
        "pl": "Dodaj elementy do tego folderu z menu kontekstowego",
    },
    "timeline.unpin": {"fr": "Désépingler", "de": "Lösen", "es": "Desfijar", "pl": "Odepnij"},
    "timeline.pin": {"fr": "Épingler", "de": "Anheften", "es": "Fijar", "pl": "Przypnij"},
    "timeline.addToFolder": {"fr": "Ajouter au dossier", "de": "Zum Ordner hinzufügen", "es": "Añadir a carpeta", "pl": "Dodaj do folderu"},
    "timeline.removeFromFolder": {"fr": "Retirer du dossier", "de": "Aus Ordner entfernen", "es": "Quitar de carpeta", "pl": "Usuń z folderu"},
    "timeline.delete": {"fr": "Supprimer", "de": "Löschen", "es": "Eliminar", "pl": "Usuń"},
    "timeline.removeFromFolderAction": {"fr": "Retirer du dossier", "de": "Aus Ordner entfernen", "es": "Quitar de carpeta", "pl": "Usuń z folderu"},
    "timeline.copy": {"fr": "Copier dans le presse-papiers", "de": "In Zwischenablage kopieren", "es": "Copiar al portapapeles", "pl": "Kopiuj do schowka"},
    "timeline.copyPlain": {"fr": "Copier en texte brut", "de": "Als Klartext kopieren", "es": "Copiar como texto plano", "pl": "Kopiuj jako zwykły tekst"},
    "timeline.edit": {"fr": "Modifier", "de": "Bearbeiten", "es": "Editar", "pl": "Edytuj"},
    "timeline.cancel": {"fr": "Annuler", "de": "Abbrechen", "es": "Cancelar", "pl": "Anuluj"},
    "timeline.create": {"fr": "Créer", "de": "Erstellen", "es": "Crear", "pl": "Utwórz"},
    "settings.tab.about": {"fr": "À propos", "de": "Über", "es": "Acerca de", "pl": "Informacje"},
    "settings.tab.general": {"fr": "Général", "de": "Allgemein", "es": "General", "pl": "Ogólne"},
    "settings.tab.privacy": {"fr": "Confidentialité", "de": "Datenschutz", "es": "Privacidad", "pl": "Prywatność"},
    "settings.tab.folders": {"fr": "Dossiers", "de": "Ordner", "es": "Carpetas", "pl": "Foldery"},
    "settings.tab.stack": {"fr": "Pile", "de": "Stapel", "es": "Pila", "pl": "Stos"},
    "settings.tab.storage": {"fr": "Stockage", "de": "Speicher", "es": "Almacenamiento", "pl": "Pamięć"},
    "settings.version": {"fr": "Pastel it！ %@ (%@)", "de": "Pastel it！ %@ (%@)", "es": "Pastel it！ %@ (%@)", "pl": "Pastel it！ %@ (%@)"},
    "settings.aboutBlurb": {
        "fr": "Pastel it！ est un gestionnaire de presse-papiers local. L'historique reste sur ce Mac.",
        "de": "Pastel it！ ist ein lokaler Zwischenablage-Manager. Der Verlauf bleibt auf diesem Mac.",
        "es": "Pastel it！ es un gestor de portapapeles local. El historial permanece en este Mac.",
        "pl": "Pastel it！ to lokalny menedżer schowka. Historia pozostaje na tym Macu.",
    },
    "settings.versionLabel": {"fr": "Version", "de": "Version", "es": "Versión", "pl": "Wersja"},
    "settings.showTutorial": {"fr": "Afficher le tutoriel…", "de": "Tutorial anzeigen…", "es": "Mostrar tutorial…", "pl": "Pokaż samouczek…"},
    "settings.whatsNew": {"fr": "Nouveautés…", "de": "Neuigkeiten…", "es": "Novedades…", "pl": "Co nowego…"},
    "settings.checkingUpdates": {"fr": "Recherche de mises à jour…", "de": "Suche nach Updates…", "es": "Buscando actualizaciones…", "pl": "Sprawdzanie aktualizacji…"},
    "settings.pauseCapture": {"fr": "Suspendre la capture du presse-papiers", "de": "Zwischenablage-Erfassung pausieren", "es": "Pausar captura del portapapeles", "pl": "Wstrzymaj przechwytywanie schowka"},
    "settings.pastePlainDefault": {
        "fr": "Coller en texte brut par défaut",
        "de": "Standardmäßig als Klartext einfügen",
        "es": "Pegar como texto plano por defecto",
        "pl": "Domyślnie wklejaj jako zwykły tekst",
    },
    "settings.plainTextFootnote": {
        "fr": "⌃⌘V colle une fois en texte brut, puis restaure le presse-papiers d'origine (accessibilité requise pour le collage auto). Dans l'historique, ⇧↩ colle la sélection en texte brut.",
        "de": "⌃⌘V fügt einmal als Text ein und stellt die ursprüngliche Zwischenablage wieder her (Bedienungshilfen für Auto-Einfügen). Im Verlauf fügt ⇧↩ die Auswahl als Text ein.",
        "es": "⌃⌘V pega una vez como texto plano y restaura el portapapeles original (se requiere accesibilidad para pegado automático). En el historial, ⇧↩ pega la selección como texto plano.",
        "pl": "⌃⌘V wkleja raz jako zwykły tekst, potem przywraca oryginalny schowek (wymagana dostępność do auto-wklejania). W historii ⇧↩ wkleja zaznaczenie jako zwykły tekst.",
    },
    "settings.launchAtLogin": {"fr": "Ouvrir à la connexion", "de": "Beim Anmelden öffnen", "es": "Abrir al iniciar sesión", "pl": "Uruchamiaj przy logowaniu"},
    "settings.keepHistory": {"fr": "Conserver l'historique", "de": "Verlauf behalten", "es": "Conservar historial", "pl": "Zachowaj historię"},
    "settings.maxHistoryItems": {"fr": "Nombre max. d'éléments", "de": "Max. Verlaufseinträge", "es": "Máx. elementos del historial", "pl": "Maks. liczba elementów historii"},
    "settings.clipboardPolling": {"fr": "Interrogation du presse-papiers", "de": "Zwischenablage-Abfrage", "es": "Sondeo del portapapeles", "pl": "Odpytywanie schowka"},
    "settings.seconds": {"fr": "s", "de": "s", "es": "s", "pl": "s"},
    "settings.stackDirection": {"fr": "Direction de collage par défaut", "de": "Standard-Einfügerichtung", "es": "Dirección de pegado predeterminada", "pl": "Domyślny kierunek wklejania"},
    "settings.stackFootnote": {
        "fr": "⇧⌘C ouvre ou ferme la pile de collage. Tant qu'elle contient des éléments, ⌘V dans une app colle le suivant (accessibilité requise). Les contrôles sont dans le panneau Pile et le menu ⋯.",
        "de": "⇧⌘C öffnet oder schließt den Einfügestapel. Solange Einträge vorhanden sind, fügt ⌘V in einer App den nächsten ein (Bedienungshilfen erforderlich). Steuerung im Stapel-Panel und im ⋯-Menü.",
        "es": "⇧⌘C abre o cierra la pila de pegado. Mientras tenga elementos, ⌘V en cualquier app pega el siguiente (se requiere accesibilidad). Los controles están en el panel Pila y el menú ⋯.",
        "pl": "⇧⌘C otwiera lub zamyka stos wklejania. Gdy ma elementy, ⌘V w dowolnej aplikacji wkleja następny (wymagana dostępność). Sterowanie w panelu Stos i menu ⋯.",
    },
    "settings.maxBinaryStorage": {
        "fr": "Stockage binaire max. : %lld Mo",
        "de": "Max. Binärspeicher: %lld MB",
        "es": "Almacenamiento binario máx.: %lld MB",
        "pl": "Maks. pamięć binarna: %lld MB",
    },
    "settings.pruneNow": {"fr": "Nettoyer maintenant", "de": "Jetzt bereinigen", "es": "Limpiar ahora", "pl": "Oczyść teraz"},
    "settings.clearKeepPinned": {
        "fr": "Effacer l'historique, garder les épinglés",
        "de": "Verlauf löschen, Angeheftetes behalten",
        "es": "Borrar historial, conservar fijados",
        "pl": "Wyczyść historię, zachowaj przypięte",
    },
    "settings.clearAllHistory": {"fr": "Tout effacer", "de": "Gesamten Verlauf löschen", "es": "Borrar todo el historial", "pl": "Wyczyść całą historię"},
    "folders.pinnedFooter": {
        "fr": "L'onglet Épinglés ne peut pas être renommé ni supprimé. Utilisez Épingler / Désépingler sur les éléments.",
        "de": "Der Tab Angeheftet kann nicht umbenannt oder gelöscht werden. Anheften/Lösen über die Einträge.",
        "es": "La pestaña Fijados no se puede renombrar ni eliminar. Usa Fijar / Desfijar en los elementos.",
        "pl": "Karty Przypięte nie można zmienić nazwy ani usunąć. Użyj Przypnij / Odepnij na elementach.",
    },
    "folders.noCustom": {"fr": "Aucun dossier personnalisé", "de": "Keine benutzerdefinierten Ordner", "es": "No hay carpetas personalizadas", "pl": "Brak własnych folderów"},
    "folders.rename": {"fr": "Renommer…", "de": "Umbenennen…", "es": "Renombrar…", "pl": "Zmień nazwę…"},
    "folders.addHelp": {"fr": "Ajouter un dossier", "de": "Ordner hinzufügen", "es": "Añadir carpeta", "pl": "Dodaj folder"},
    "folders.renameHelp": {"fr": "Renommer le dossier", "de": "Ordner umbenennen", "es": "Renombrar carpeta", "pl": "Zmień nazwę folderu"},
    "folders.deleteHelp": {"fr": "Supprimer le dossier", "de": "Ordner löschen", "es": "Eliminar carpeta", "pl": "Usuń folder"},
    "folders.footer": {
        "fr": "Créez jusqu'à %lld dossiers personnalisés. Ils apparaissent à côté de Par défaut et Épinglés. Les éléments des dossiers sont conservés lors du nettoyage.",
        "de": "Bis zu %lld benutzerdefinierte Ordner. Sie erscheinen neben Standard und Angeheftet. Ordner-Einträge bleiben bei der Bereinigung erhalten.",
        "es": "Crea hasta %lld carpetas personalizadas. Aparecen junto a Predeterminado y Fijados. Los elementos en carpetas se conservan al limpiar.",
        "pl": "Utwórz do %lld własnych folderów. Pojawią się obok Domyślne i Przypięte. Elementy w folderach są zachowywane przy czyszczeniu.",
    },
    "folders.renameTitle": {"fr": "Renommer le dossier", "de": "Ordner umbenennen", "es": "Renombrar carpeta", "pl": "Zmień nazwę folderu"},
    "folders.namePlaceholder": {"fr": "Nom du dossier", "de": "Ordnername", "es": "Nombre de carpeta", "pl": "Nazwa folderu"},
    "folders.renameConfirm": {"fr": "Renommer", "de": "Umbenennen", "es": "Renombrar", "pl": "Zmień nazwę"},
    "privacy.noIgnoredApps": {"fr": "Aucune app ignorée", "de": "Keine ignorierten Apps", "es": "No hay apps ignoradas", "pl": "Brak ignorowanych aplikacji"},
    "privacy.addApp": {"fr": "Ajouter une app", "de": "App hinzufügen", "es": "Añadir app", "pl": "Dodaj aplikację"},
    "privacy.removeApp": {"fr": "Retirer l'app", "de": "App entfernen", "es": "Quitar app", "pl": "Usuń aplikację"},
    "privacy.ignoredApps": {"fr": "Apps ignorées", "de": "Ignorierte Apps", "es": "Apps ignoradas", "pl": "Ignorowane aplikacje"},
    "privacy.ignoredAppsFooter": {
        "fr": "Les copies dans ces apps ne sont jamais enregistrées. Utile pour les gestionnaires de mots de passe et apps sensibles.",
        "de": "Kopien in diesen Apps werden nie gespeichert. Für Passwort-Manager und sensible Apps.",
        "es": "Las copias en estas apps nunca se guardan. Útil para gestores de contraseñas y apps sensibles.",
        "pl": "Kopie w tych aplikacjach nie są zapisywane. Dla menedżerów haseł i wrażliwych aplikacji.",
    },
    "privacy.protectedContent": {"fr": "Contenu protégé", "de": "Geschützter Inhalt", "es": "Contenido protegido", "pl": "Chroniona zawartość"},
    "privacy.protectedBlurb": {
        "fr": "Les marqueurs sensibles du presse-papiers — champs de mot de passe, clips temporaires — sont ignorés automatiquement.",
        "de": "Sensible Zwischenablage-Markierungen — Passwortfelder, temporäre Clips — werden automatisch ignoriert.",
        "es": "Los marcadores sensibles del portapapeles — campos de contraseña, clips temporales — se ignoran automáticamente.",
        "pl": "Wrażliwe znaczniki schowka — pola haseł, tymczasowe klipy — są automatycznie ignorowane.",
    },
    "privacy.protectedFooter": {
        "fr": "Apps ignorées excluent toute une app. Contenu protégé exclut uniquement les données sensibles marquées, de toute app.",
        "de": "Ignorierte Apps überspringen alles von einer App. Geschützter Inhalt nur markierte sensible Daten, von jeder App.",
        "es": "Apps ignoradas omiten todo de una app. Contenido protegido solo omite datos sensibles marcados, de cualquier app.",
        "pl": "Ignorowane aplikacje pomijają całą aplikację. Chroniona zawartość pomija tylko oznaczone dane wrażliwe z dowolnej aplikacji.",
    },
    "privacy.addIgnoredApp": {"fr": "Ajouter une app ignorée", "de": "Ignorierte App hinzufügen", "es": "Añadir app ignorada", "pl": "Dodaj ignorowaną aplikację"},
    "privacy.chooseApp": {"fr": "Choisir…", "de": "Auswählen…", "es": "Elegir…", "pl": "Wybierz…"},
    "privacy.search": {"fr": "Rechercher", "de": "Suchen", "es": "Buscar", "pl": "Szukaj"},
    "privacy.loadingApps": {"fr": "Chargement des apps…", "de": "Apps werden geladen…", "es": "Cargando apps…", "pl": "Ładowanie aplikacji…"},
    "privacy.chooseAppPanel": {"fr": "Choisir une app à ignorer", "de": "App zum Ignorieren auswählen", "es": "Elegir una app para ignorar", "pl": "Wybierz aplikację do ignorowania"},
    "onboarding.capture.title": {"fr": "Copier pour enregistrer", "de": "Kopieren zum Speichern", "es": "Copiar para guardar", "pl": "Kopiuj, aby zapisać"},
    "onboarding.paste.title": {"fr": "Choisir dans l'historique", "de": "Aus dem Verlauf wählen", "es": "Elegir del historial", "pl": "Wybierz z historii"},
    "onboarding.browse.title": {"fr": "Aperçu et modification", "de": "Vorschau und Bearbeitung", "es": "Vista previa y edición", "pl": "Podgląd i edycja"},
    "onboarding.organize.title": {"fr": "Collage multiple", "de": "Mehrfach-Einfügen", "es": "Pegado múltiple", "pl": "Wklejanie wielokrotne"},
    "onboarding.stack.title": {"fr": "Pile de collage", "de": "Einfügestapel", "es": "Pila de pegado", "pl": "Stos wklejania"},
    "onboarding.capture.caption": {
        "fr": "Copiez n'importe quoi — Pastel it！ l'enregistre et affiche ⌘C dans la barre de menus.",
        "de": "Alles kopieren — Pastel it！ speichert es und blinkt ⌘C in der Menüleiste.",
        "es": "Copia cualquier cosa — Pastel it！ la guarda y muestra ⌘C en la barra de menús.",
        "pl": "Kopiuj cokolwiek — Pastel it！ zapisuje i miga ⌘C na pasku menu.",
    },
    "onboarding.paste.caption": {
        "fr": "⇧⌘V ouvre l'historique. Double-cliquez un élément, puis ⌘V — ou ⌃⌘V sans mise en forme.",
        "de": "⇧⌘V öffnet den Verlauf. Doppelklick auf Eintrag, dann ⌘V — oder ⌃⌘V ohne Formatierung.",
        "es": "⇧⌘V abre el historial. Doble clic en un elemento, luego ⌘V — o ⌃⌘V sin formato.",
        "pl": "⇧⌘V otwiera historię. Kliknij dwukrotnie element, potem ⌘V — lub ⌃⌘V bez formatowania.",
    },
    "onboarding.browse.caption": {
        "fr": "Appuyez sur Espace pour prévisualiser au-dessus de l'historique. Cliquez le texte pour modifier.",
        "de": "Leertaste für die Vorschau über dem Verlauf. Text anklicken zum Bearbeiten.",
        "es": "Pulsa Espacio para previsualizar sobre el historial. Haz clic en el texto para editar.",
        "pl": "Naciśnij Spację, aby podejrzeć nad historią. Kliknij tekst, aby edytować.",
    },
    "onboarding.organize.caption": {
        "fr": "⌘-cliquez plusieurs éléments, puis Entrée pour les coller dans l'ordre.",
        "de": "⌘-Klick auf mehrere Einträge, dann Eingabe zum Einfügen in Reihenfolge.",
        "es": "⌘-clic en varios elementos, luego Intro para pegarlos en orden.",
        "pl": "⌘-kliknij kilka elementów, potem Return, aby wkleić w kolejności.",
    },
    "onboarding.stack.caption": {
        "fr": "⇧⌘C ouvre une file à droite. Copiez plusieurs éléments, puis ⌘V dans l'app cible un par un.",
        "de": "⇧⌘C öffnet eine Warteschlange rechts. Mehrere Dinge kopieren, dann ⌘V in der Ziel-App nacheinander.",
        "es": "⇧⌘C abre una cola a la derecha. Copia varias cosas, luego ⌘V en la app destino una a una.",
        "pl": "⇧⌘C otwiera kolejkę po prawej. Skopiuj kilka rzeczy, potem ⌘V w docelowej aplikacji po kolei.",
    },
    "onboarding.step.copy": {"fr": "Copier", "de": "Kopieren", "es": "Copiar", "pl": "Kopiuj"},
    "onboarding.step.saved": {"fr": "Enregistré", "de": "Gespeichert", "es": "Guardado", "pl": "Zapisano"},
    "onboarding.step.open": {"fr": "Ouvrir", "de": "Öffnen", "es": "Abrir", "pl": "Otwórz"},
    "onboarding.step.doubleClick": {"fr": "Double-clic", "de": "Doppelklick", "es": "Doble clic", "pl": "Dwuklik"},
    "onboarding.step.paste": {"fr": "Coller", "de": "Einfügen", "es": "Pegar", "pl": "Wklej"},
    "onboarding.step.plain": {"fr": "Brut", "de": "Klartext", "es": "Plano", "pl": "Zwykły"},
    "onboarding.step.space": {"fr": "Espace", "de": "Leertaste", "es": "Espacio", "pl": "Spacja"},
    "onboarding.step.preview": {"fr": "Aperçu", "de": "Vorschau", "es": "Vista previa", "pl": "Podgląd"},
    "onboarding.step.edit": {"fr": "Modifier", "de": "Bearbeiten", "es": "Editar", "pl": "Edytuj"},
    "onboarding.step.cmdClick": {"fr": "⌘-clic", "de": "⌘-Klick", "es": "⌘-clic", "pl": "⌘-klik"},
    "onboarding.step.order": {"fr": "Ordre", "de": "Reihenfolge", "es": "Orden", "pl": "Kolejność"},
    "onboarding.step.return": {"fr": "Entrée", "de": "Eingabe", "es": "Intro", "pl": "Return"},
    "onboarding.demo.next": {"fr": "SUIVANT", "de": "WEITER", "es": "SIGUIENTE", "pl": "DALEJ"},
    "onboarding.demo.clickToEdit": {"fr": "Cliquer pour modifier", "de": "Klicken zum Bearbeiten", "es": "Haz clic para editar", "pl": "Kliknij, aby edytować"},
    "onboarding.demo.copyToCollect": {"fr": "Copier pour collecter", "de": "Kopieren zum Sammeln", "es": "Copiar para recopilar", "pl": "Kopiuj, aby zebrać"},
    "onboarding.demo.doubleClick": {"fr": "Double-clic", "de": "Doppelklick", "es": "Doble clic", "pl": "Dwuklik"},
    "common.cancel": {"fr": "Annuler", "de": "Abbrechen", "es": "Cancelar", "pl": "Anuluj"},
    "common.delete": {"fr": "Supprimer", "de": "Löschen", "es": "Eliminar", "pl": "Usuń"},
    "common.create": {"fr": "Créer", "de": "Erstellen", "es": "Crear", "pl": "Utwórz"},
}


# Product experience actions and recovery.
BATCH2.update({
    "removal.undoShort": {
        "fr": "Annuler",
        "de": "Rückgängig",
        "es": "Deshacer",
        "pl": "Cofnij"
    },
    "removal.namedFolder": {
        "fr": "Retirer de « %@ »",
        "de": "Aus „%@“ entfernen",
        "es": "Quitar de «%@»",
        "pl": "Usuń z „%@”"
    },
    "removal.removedFolder": {
        "fr": "Retiré de « %@ »",
        "de": "Aus „%@“ entfernt",
        "es": "Quitado de «%@»",
        "pl": "Usunięto z „%@”"
    },
    "removal.removedHistory": {
        "fr": "Retiré de l’historique",
        "de": "Aus dem Verlauf entfernt",
        "es": "Quitado del historial",
        "pl": "Usunięto z historii"
    },
    "removal.unpinned": {
        "fr": "Désépinglé",
        "de": "Losgelöst",
        "es": "Desfijado",
        "pl": "Odpięto"
    },
    "removal.restored": {
        "fr": "Retrait annulé",
        "de": "Entfernen rückgängig gemacht",
        "es": "Eliminación deshecha",
        "pl": "Cofnięto usunięcie"
    }
})

BATCH2.update({
    "action.cannotEdit": {
        "fr": "Cet élément ne peut pas être modifié",
        "de": "Dieser Eintrag kann nicht bearbeitet werden",
        "es": "Este elemento no se puede editar",
        "pl": "Nie można edytować tego elementu"
    },
    "action.copied": {
        "fr": "Copié dans le presse-papiers",
        "de": "In die Zwischenablage kopiert",
        "es": "Copiado al portapapeles",
        "pl": "Skopiowano do schowka"
    },
    "action.copiedManual": {
        "fr": "Copié. Revenez à votre app et appuyez sur ⌘V. Autorisez l’accessibilité pour coller directement.",
        "de": "Kopiert. Zur Ziel-App zurückkehren und ⌘V drücken. Für direktes Einfügen Bedienungshilfen erlauben.",
        "es": "Copiado. Vuelve a tu app y pulsa ⌘V. Permite Accesibilidad para pegar directamente.",
        "pl": "Skopiowano. Wróć do aplikacji i naciśnij ⌘V. Zezwól na dostęp do Ułatwień dostępu, aby wklejać bezpośrednio."
    },
    "action.copyOnly": {
        "fr": "Copier uniquement",
        "de": "Nur kopieren",
        "es": "Solo copiar",
        "pl": "Tylko kopiuj"
    },
    "action.copySingle": {
        "fr": "Sélectionnez un seul élément à copier. ⇧Return colle plusieurs éléments en texte brut.",
        "de": "Zum Kopieren einen Eintrag auswählen. ⇧Return fügt mehrere Einträge als reinen Text ein.",
        "es": "Selecciona un elemento para copiar. ⇧Return pega varios como texto sin formato.",
        "pl": "Wybierz jeden element do skopiowania. ⇧Return wkleja wiele elementów jako zwykły tekst."
    },
    "action.dismiss": {
        "fr": "Fermer le message",
        "de": "Meldung schließen",
        "es": "Cerrar mensaje",
        "pl": "Zamknij komunikat"
    },
    "action.enablePaste": {
        "fr": "Activer le collage direct",
        "de": "Direktes Einfügen aktivieren",
        "es": "Activar pegado directo",
        "pl": "Włącz bezpośrednie wklejanie"
    },
    "action.focusChanged": {
        "fr": "Collage arrêté : la destination ou l’autorisation a changé. Activez la destination et réessayez les éléments restants.",
        "de": "Einfügen gestoppt: Ziel oder Berechtigung geändert. Ziel aktivieren und verbleibende Einträge erneut versuchen.",
        "es": "Pegado detenido: cambió el destino o el permiso. Enfoca el destino e intenta pegar los elementos restantes.",
        "pl": "Wklejanie zatrzymane: zmienił się cel lub uprawnienie. Uaktywnij cel i spróbuj wkleić pozostałe elementy."
    },
    "action.multiPermission": {
        "fr": "Autorisez l’accessibilité pour coller plusieurs éléments, ou sélectionnez-en un pour le copier manuellement.",
        "de": "Bedienungshilfen für mehrere Einträge erlauben oder einen Eintrag zum manuellen Kopieren auswählen.",
        "es": "Permite Accesibilidad para pegar varios elementos o selecciona uno para copiarlo manualmente.",
        "pl": "Zezwól na Ułatwienia dostępu, aby wkleić wiele elementów, lub wybierz jeden do ręcznego skopiowania."
    },
    "action.paste": {
        "fr": "Collage direct",
        "de": "Direkt einfügen",
        "es": "Pegado directo",
        "pl": "Bezpośrednie wklejanie"
    },
    "action.pasteSent": {
        "fr": "Demande de collage envoyée",
        "de": "Einfügeanforderung gesendet",
        "es": "Solicitud de pegado enviada",
        "pl": "Wysłano żądanie wklejenia"
    },
    "action.permissionDetail": {
        "fr": "L’accessibilité permet à Pastel it！ d’envoyer ⌘V à l’app cible. Sans autorisation, vous pouvez toujours copier et coller manuellement.",
        "de": "Mit Bedienungshilfen kann Pastel it！ ⌘V an die Ziel-App senden. Ohne Erlaubnis können Sie weiterhin kopieren und manuell einfügen.",
        "es": "Accesibilidad permite a Pastel it！ enviar ⌘V a la app de destino. Sin permiso, puedes copiar y pegar manualmente.",
        "pl": "Ułatwienia dostępu pozwalają Pastel it！ wysyłać ⌘V do aplikacji docelowej. Bez uprawnienia nadal możesz kopiować i wklejać ręcznie."
    },
    "action.permissionNeeded": {
        "fr": "Le collage direct nécessite l’accessibilité",
        "de": "Direktes Einfügen benötigt Bedienungshilfen",
        "es": "El pegado directo requiere Accesibilidad",
        "pl": "Bezpośrednie wklejanie wymaga Ułatwień dostępu"
    },
    "action.permissionReady": {
        "fr": "Le collage direct est activé",
        "de": "Direktes Einfügen ist aktiviert",
        "es": "El pegado directo está activado",
        "pl": "Bezpośrednie wklejanie jest włączone"
    },
    "action.retry": {
        "fr": "Réessayer",
        "de": "Erneut versuchen",
        "es": "Reintentar",
        "pl": "Spróbuj ponownie"
    },
    "action.returnToApp": {
        "fr": "Revenir à l’app",
        "de": "Zur App zurückkehren",
        "es": "Volver a la app",
        "pl": "Wróć do aplikacji"
    },
    "action.selectionCount": {
        "fr": "%lld sélectionnés",
        "de": "%lld ausgewählt",
        "es": "%lld seleccionados",
        "pl": "Wybrano: %lld"
    },
    "action.setting": {
        "fr": "Action principale de l’historique",
        "de": "Hauptaktion im Verlauf",
        "es": "Acción principal del historial",
        "pl": "Główna czynność historii"
    },
    "action.settingDetail": {
        "fr": "Le double-clic, Retour et ⌘1–9 exécutent l’action choisie. Le collage direct est le réglage par défaut. ⇧Retour colle toujours en texte brut.",
        "de": "Doppelklick, Return und ⌘1–9 führen die gewählte Aktion aus. Direktes Einfügen ist der Standard. ⇧Return fügt immer reinen Text ein.",
        "es": "Doble clic, Retorno y ⌘1–9 ejecutan la acción elegida. Pegar directamente es la opción predeterminada. ⇧Retorno siempre pega texto sin formato.",
        "pl": "Dwuklik, Return i ⌘1–9 wykonują wybraną czynność. Domyślnie wklejają bezpośrednio. ⇧Return zawsze wkleja zwykły tekst."
    },
    "action.tutorial": {
        "fr": "Sélectionnez un élément, ⌘C pour copier, puis ⌘V dans votre app. Choisissez Collage direct dans les réglages pour une seule action.",
        "de": "Eintrag auswählen, mit ⌘C kopieren, dann in der Ziel-App ⌘V drücken. Für einen Schritt in den Einstellungen Direkt einfügen wählen.",
        "es": "Selecciona un elemento, copia con ⌘C y pulsa ⌘V en tu app. Elige Pegado directo en Ajustes para hacerlo en un paso.",
        "pl": "Wybierz element, skopiuj przez ⌘C i wklej przez ⌘V w aplikacji. Wybierz Bezpośrednie wklejanie w ustawieniach, aby zrobić to jednym krokiem."
    },
    "action.writeFailed": {
        "fr": "Impossible de copier. Le contenu ou le fichier joint est peut-être indisponible. Restaurez le fichier et réessayez.",
        "de": "Kopieren fehlgeschlagen. Inhalt oder Anhang möglicherweise nicht verfügbar. Datei wiederherstellen und erneut versuchen.",
        "es": "No se pudo copiar. El contenido o archivo adjunto podría no estar disponible. Restaura el archivo y reintenta.",
        "pl": "Nie udało się skopiować. Treść lub załącznik mogą być niedostępne. Przywróć plik i spróbuj ponownie."
    },
    "removal.clearKeepSaved": {
        "fr": "Effacer l’historique, garder les épinglés et dossiers…",
        "de": "Verlauf löschen, Angeheftetes und Ordner behalten…",
        "es": "Borrar historial, conservar fijados y carpetas…",
        "pl": "Wyczyść historię, zachowaj przypięte i foldery…"
    },
    "removal.confirmCount": {
        "fr": "%lld éléments seront supprimés définitivement. Cette action est irréversible et met fin à l’annulation des retraits précédents.",
        "de": "%lld Einträge werden endgültig gelöscht. Dies ist nicht rückgängig zu machen und beendet das Rückgängigmachen vorheriger Entfernungen.",
        "es": "Se eliminarán permanentemente %lld elementos. No se puede deshacer y finaliza la opción de deshacer retiradas anteriores.",
        "pl": "Liczba elementów do trwałego usunięcia: %lld. Nie można tego cofnąć; kończy to też możliwość cofnięcia wcześniejszych usunięć."
    },
    "removal.confirmDelete": {
        "fr": "Supprimer les éléments vérifiés",
        "de": "Geprüfte Einträge löschen",
        "es": "Eliminar elementos revisados",
        "pl": "Usuń sprawdzone elementy"
    },
    "removal.confirmTitle": {
        "fr": "Vérifier le nettoyage de l’historique",
        "de": "Verlaufsbereinigung prüfen",
        "es": "Revisar limpieza del historial",
        "pl": "Sprawdź czyszczenie historii"
    },
    "removal.everywhere": {
        "fr": "Supprimer partout",
        "de": "Überall löschen",
        "es": "Eliminar de todas partes",
        "pl": "Usuń ze wszystkich miejsc"
    },
    "removal.everywhereDetail": {
        "fr": "Supprimer cet élément de l’historique, des épinglés et de tous les dossiers ? Cette action est irréversible.",
        "de": "Diesen Eintrag aus Verlauf, Angeheftet und allen Ordnern löschen? Dies kann nicht rückgängig gemacht werden.",
        "es": "¿Eliminar este elemento del historial, los fijados y todas las carpetas? No se puede deshacer.",
        "pl": "Usunąć ten element z historii, przypiętych i wszystkich folderów? Nie można tego cofnąć."
    },
    "removal.failedTitle": {
        "fr": "L’historique n’a pas été modifié",
        "de": "Verlauf wurde nicht geändert",
        "es": "El historial no se modificó",
        "pl": "Historia nie została zmieniona"
    },
    "removal.history": {
        "fr": "Retirer de l’historique",
        "de": "Aus Verlauf entfernen",
        "es": "Retirar del historial",
        "pl": "Usuń z historii"
    },
    "removal.includeSaved": {
        "fr": "Les épinglés et tous les dossiers sont inclus. Les dossiers eux-mêmes sont conservés.",
        "de": "Angeheftete Einträge und alle Ordnerinhalte sind eingeschlossen. Die Ordner selbst bleiben erhalten.",
        "es": "Incluye los fijados y todas las carpetas. Las carpetas en sí se conservarán.",
        "pl": "Obejmuje przypięte elementy i wszystkie foldery. Same foldery zostaną zachowane."
    },
    "removal.keepSaved": {
        "fr": "Les éléments épinglés et ceux des dossiers seront conservés.",
        "de": "Angeheftete Einträge und Einträge in Ordnern bleiben erhalten.",
        "es": "Se conservarán los elementos fijados y los de las carpetas.",
        "pl": "Przypięte elementy i elementy w folderach zostaną zachowane."
    },
    "removal.newRetention": {
        "fr": "Nouvelle durée de conservation : %@",
        "de": "Neue Aufbewahrungsdauer: %@",
        "es": "Nuevo periodo de conservación: %@",
        "pl": "Nowy okres przechowywania: %@"
    },
    "removal.saveFailed": {
        "fr": "Impossible d’enregistrer. L’historique a été restauré ; réessayez.",
        "de": "Änderung konnte nicht gespeichert werden. Verlauf wiederhergestellt; erneut versuchen.",
        "es": "No se pudo guardar el cambio. Se restauró el historial; reintenta.",
        "pl": "Nie udało się zapisać zmiany. Historia została przywrócona; spróbuj ponownie."
    },
    "removal.stillSaved": {
        "fr": "Retiré de l’historique ; conservé dans les épinglés ou les dossiers",
        "de": "Aus Verlauf entfernt; weiterhin angeheftet oder in Ordnern gespeichert",
        "es": "Retirado del historial; sigue guardado en fijados o carpetas",
        "pl": "Usunięto z historii; nadal zapisane w przypiętych lub folderach"
    },
    "removal.undo": {
        "fr": "Annuler le retrait",
        "de": "Entfernen rückgängig machen",
        "es": "Deshacer retirada",
        "pl": "Cofnij usunięcie"
    },
    "removal.undoHelp": {
        "fr": "Annuler les retraits récents pendant 30 secondes (⌘Z).",
        "de": "Entfernungen 30 Sekunden lang rückgängig machen (⌘Z).",
        "es": "Deshacer retiradas recientes durante 30 segundos (⌘Z).",
        "pl": "Cofnij ostatnie usunięcia przez 30 sekund (⌘Z)."
    }
})


# Native settings navigation and grouped forms.
BATCH2.update({
    "settings.windowTitle": {
        "fr": "Réglages de Pastel it！",
        "de": "Pastel it！ Einstellungen",
        "es": "Ajustes de Pastel it！",
        "pl": "Ustawienia Pastel it！"
    },
    "settings.sidebar.clipboard": {"fr": "Presse-papiers", "de": "Zwischenablage", "es": "Portapapeles", "pl": "Schowek"},
    "settings.tab.clipboard": {
        "fr": "Presse-papiers et historique",
        "de": "Zwischenablage & Verlauf",
        "es": "Portapapeles e historial",
        "pl": "Schowek i historia"
    },
    "settings.group.startup": {
        "fr": "Démarrage",
        "de": "Start",
        "es": "Inicio",
        "pl": "Uruchamianie"
    },
    "settings.group.pasting": {
        "fr": "Collage",
        "de": "Einfügen",
        "es": "Pegado",
        "pl": "Wklejanie"
    },
    "settings.group.shortcuts": {
        "fr": "Raccourcis clavier",
        "de": "Tastaturkurzbefehle",
        "es": "Atajos de teclado",
        "pl": "Skróty klawiszowe"
    },
    "settings.group.capture": {
        "fr": "Capture",
        "de": "Erfassung",
        "es": "Captura",
        "pl": "Przechwytywanie"
    },
    "settings.group.history": {
        "fr": "Historique",
        "de": "Verlauf",
        "es": "Historial",
        "pl": "Historia"
    },
    "settings.group.advanced": {
        "fr": "Avancé",
        "de": "Erweitert",
        "es": "Avanzado",
        "pl": "Zaawansowane"
    },
    "settings.group.permissions": {
        "fr": "Autorisations système",
        "de": "Systemberechtigungen",
        "es": "Permisos del sistema",
        "pl": "Uprawnienia systemowe"
    },
    "settings.group.cleanup": {
        "fr": "Nettoyage de l’historique",
        "de": "Verlauf bereinigen",
        "es": "Limpieza del historial",
        "pl": "Czyszczenie historii"
    },
    "settings.group.updates": {
        "fr": "Mises à jour",
        "de": "Updates",
        "es": "Actualizaciones",
        "pl": "Aktualizacje"
    },
    "settings.automaticallyCheckUpdates": {
        "fr": "Rechercher automatiquement les mises à jour",
        "de": "Automatisch nach Updates suchen",
        "es": "Buscar actualizaciones automáticamente",
        "pl": "Automatycznie sprawdzaj dostępność aktualizacji"
    },
    "settings.automaticallyDownloadUpdates": {
        "fr": "Télécharger automatiquement les mises à jour",
        "de": "Updates automatisch laden",
        "es": "Descargar actualizaciones automáticamente",
        "pl": "Automatycznie pobieraj aktualizacje"
    },
    "settings.automaticUpdatesHelp": {
        "fr": "Les mises à jour sont téléchargées en arrière-plan. Lorsqu’une mise à jour est prête, vous serez invité à redémarrer Pastel it！. Vous pouvez aussi l’installer à la fermeture de l’application.",
        "de": "Updates werden im Hintergrund geladen. Sobald ein Update bereit ist, werden Sie aufgefordert, Pastel it！ neu zu starten. Sie können es auch beim Beenden der App installieren.",
        "es": "Las actualizaciones se descargan en segundo plano. Cuando una actualización esté lista, se te pedirá que reinicies Pastel it！. También puedes instalarla al salir de la aplicación.",
        "pl": "Aktualizacje są pobierane w tle. Gdy aktualizacja będzie gotowa, pojawi się prośba o ponowne uruchomienie Pastel it！. Możesz ją też zainstalować przy zamknięciu aplikacji."
    },
    "settings.group.help": {
        "fr": "Aide",
        "de": "Hilfe",
        "es": "Ayuda",
        "pl": "Pomoc"
    }
})


# Local repair additions use the generator's English fallback where untranslated.
BATCH2.update({
    "shortcuts.invalid": {},
    "shortcuts.duplicate": {},
    "shortcuts.unavailable": {},
    "shortcuts.registrationFailed": {},
    "shortcuts.edit": {},
    "shortcuts.reset": {},
    "shortcuts.help": {},
    "shortcuts.recordTitle": {},
    "shortcuts.recordHelp": {},
    "shortcuts.listening": {},
    "shortcuts.plainFootnote": {},
    "shortcuts.stackFootnote": {},
    "shortcuts.stackTutorial": {},
    "permissions.restartTitle": {},
    "permissions.restartDetail": {},
    "permissions.restartHint": {},
    "permissions.understood": {}
})


BATCH2.update({
    "shortcuts.unassigned": {},
    "shortcuts.stackTutorialWithoutBinding": {}
})


# OCR and timeline additions use English where not translated yet.
BATCH2.update({
    "settings.tab.ocr": {},
    "ocr.recognition": {},
    "ocr.enabled": {},
    "ocr.enabledHelp": {},
    "ocr.tables": {},
    "ocr.tablesHelp": {},
    "ocr.automaticLanguage": {},
    "ocr.accuracy": {},
    "ocr.accurate": {},
    "ocr.fast": {},
    "ocr.correction": {},
    "ocr.minimumHeight": {},
    "ocr.parametersHelp": {},
    "ocr.reset": {},
    "quickPaste.title": {},
    "quickPaste.enabled": {},
    "quickPaste.help": {},
    "quickPaste.text": {},
    "quickPaste.images": {},
    "quickPaste.files": {},
    "quickPaste.scopeHelp": {},
    "quickPaste.emptyScope": {},
    "quickPaste.noContent": {},
    "quickPaste.changed": {},
    "quickPaste.manual": {},
    "quickPaste.done": {},
    "timeline.timeRuler": {},
    "timeline.timeRulerHelp": {}
})


BATCH2.update({"settings.privateUpdates": {}})

BATCH2["menu.statusTooltip"].update({"fr": "Pastel it！ — Historique du presse-papiers", "de": "Pastel it！ — Zwischenablageverlauf", "es": "Pastel it！ — Historial del portapapeles", "pl": "Pastel it！ — Historia schowka"})


# Native UI simplification and active shortcut wording.
BATCH2.update({
    "shortcuts.timelineFootnote": {
        "de": "⇧⌘C öffnet den Verlauf. Schnelles Einfügen wird in den OCR-Einstellungen konfiguriert.",
        "fr": "⇧⌘C ouvre l’historique. Configurez le collage rapide dans les réglages OCR.",
        "es": "⇧⌘C abre el historial. Configura Pegado rápido en los ajustes de OCR.",
        "pl": "⇧⌘C otwiera historię. Szybkie wklejanie skonfigurujesz w ustawieniach OCR."
    },
    "ocr.languages": {
        "de": "Sprachen",
        "fr": "Langues",
        "es": "Idiomas",
        "pl": "Języki"
    },
    "shortcuts.binding": {
        "de": "Tastaturkurzbefehl",
        "fr": "Raccourci clavier",
        "es": "Atajo de teclado",
        "pl": "Skrót klawiszowy"
    },
    "timeline.folders": {
        "de": "Sammlungen",
        "fr": "Collections",
        "es": "Colecciones",
        "pl": "Kolekcje"
    },
    "quickPaste.help": {
        "de": "Aktuelle Zwischenablage als reinen Text einfügen: ⇧⌘V. Verlauf öffnen: ⇧⌘C.",
        "fr": "Convertir le presse-papiers en texte brut et coller : ⇧⌘V. Ouvrir l’historique : ⇧⌘C.",
        "es": "Convierte el portapapeles en texto sin formato y pega con ⇧⌘V. Abre el historial con ⇧⌘C.",
        "pl": "Wklej bieżący schowek jako zwykły tekst: ⇧⌘V. Otwórz historię: ⇧⌘C."
    },
    "action.settingDetail": {
        "de": "Doppelklick, Return und ⌘1–9 führen die gewählte Aktion aus. Standard: direkt einfügen.",
        "fr": "Double-clic, Retour et ⌘1–9 exécutent l’action choisie. Par défaut : coller directement.",
        "es": "Doble clic, Intro y ⌘1–9 ejecutan la acción seleccionada. Por defecto: pegar directamente.",
        "pl": "Dwuklik, Return i ⌘1–9 wykonują wybraną czynność. Domyślnie: wklej bezpośrednio."
    },
    "action.copySingle": {
        "de": "Ein Element zum Kopieren wählen oder Return drücken, um die Auswahl der Reihe nach einzufügen.",
        "fr": "Sélectionnez un élément à copier ou appuyez sur Retour pour coller la sélection dans l’ordre.",
        "es": "Selecciona un elemento para copiar o pulsa Intro para pegar la selección en orden.",
        "pl": "Wybierz element do skopiowania lub naciśnij Return, aby wkleić zaznaczenie po kolei."
    },
    "onboarding.paste.caption": {
        "de": "⇧⌘C öffnet den Verlauf. Ein Element auswählen und kopieren oder einfügen.",
        "fr": "⇧⌘C ouvre l’historique. Sélectionnez un élément à copier ou coller.",
        "es": "⇧⌘C abre el historial. Selecciona un elemento para copiar o pegar.",
        "pl": "⇧⌘C otwiera historię. Wybierz element do skopiowania lub wklejenia."
    }
})

# Accessible label for the native image/text preview picker.
BATCH2.update({
    "preview.content": {
        "fr": "Contenu de l’aperçu",
        "de": "Vorschauinhalt",
        "es": "Contenido de la vista previa",
        "pl": "Zawartość podglądu"
    }
})

# Settings sidebar and onboarding native layout refinement.
BATCH2.update({
    "settings.sidebar.ocr": {
        "fr": "OCR",
        "de": "OCR",
        "es": "OCR",
        "pl": "OCR"
    },
    "onboarding.skip": {
        "fr": "Ignorer",
        "de": "Überspringen",
        "es": "Omitir",
        "pl": "Pomiń"
    },
    "onboarding.back": {
        "fr": "Retour",
        "de": "Zurück",
        "es": "Atrás",
        "pl": "Wstecz"
    },
    "onboarding.continue": {
        "fr": "Continuer",
        "de": "Weiter",
        "es": "Continuar",
        "pl": "Dalej"
    },
    "onboarding.done": {
        "fr": "Terminé",
        "de": "Fertig",
        "es": "Listo",
        "pl": "Gotowe"
    },
    "onboarding.getStarted": {
        "fr": "Commencer",
        "de": "Los geht’s",
        "es": "Empezar",
        "pl": "Rozpocznij"
    }
})

# Clipboard candidate-bar presentation.
BATCH2.update({
    "settings.group.displayStyle": {
        "fr": "Style d’affichage",
        "de": "Darstellungsstil",
        "es": "Estilo de vista",
        "pl": "Styl wyświetlania"
    },
    "clipboard.style.picker": {
        "fr": "Présentation",
        "de": "Darstellung",
        "es": "Presentación",
        "pl": "Sposób wyświetlania"
    },
    "clipboard.style.timeline": {
        "fr": "Chronologie",
        "de": "Zeitleiste",
        "es": "Cronología",
        "pl": "Oś czasu"
    },
    "clipboard.style.candidateBar": {
        "fr": "Barre de sélection",
        "de": "Auswahlleiste",
        "es": "Barra de opciones",
        "pl": "Pasek wyboru"
    },
    "clipboard.style.help": {
        "fr": "Choisissez la chronologie ou une barre des éléments récents. Le même raccourci ouvre les deux.",
        "de": "Zeitleiste oder kompakte Auswahl der letzten Einträge. Beide öffnen sich mit demselben Kurzbefehl.",
        "es": "Elige la cronología o una barra de elementos recientes. Ambas usan el mismo atajo.",
        "pl": "Wybierz oś czasu lub pasek ostatnich elementów. Oba widoki otwiera ten sam skrót."
    },
    "candidateBar.collapse": {
        "fr": "Réduire",
        "de": "Weniger anzeigen",
        "es": "Mostrar menos",
        "pl": "Zwiń"
    },
    "candidateBar.expand": {
        "fr": "Afficher plus",
        "de": "Mehr anzeigen",
        "es": "Mostrar más",
        "pl": "Rozwiń"
    },
    "candidateBar.close": {
        "fr": "Fermer",
        "de": "Schließen",
        "es": "Cerrar",
        "pl": "Zamknij"
    },
    "candidateBar.empty": {
        "fr": "Aucun élément récent",
        "de": "Keine letzten Einträge",
        "es": "Sin elementos recientes",
        "pl": "Brak ostatnich elementów"
    },
    "candidateBar.emptyDetail": {
        "fr": "Copiez du texte, des images ou des fichiers pour les voir ici.",
        "de": "Kopierter Text, Bilder und Dateien erscheinen hier.",
        "es": "Copia texto, imágenes o archivos para verlos aquí.",
        "pl": "Skopiuj tekst, obrazy lub pliki, aby pojawiły się tutaj."
    },
    "candidateBar.footer": {
        "fr": "1–5 : sélectionner · Tab : développer/réduire",
        "de": "1–5 auswählen · Tab auf-/zuklappen",
        "es": "1–5: elegir · Tab: expandir/contraer",
        "pl": "1–5: wybór · Tab: rozwiń/zwiń"
    },
    "candidateBar.moreFiles": {
        "fr": "+%lld autres",
        "de": "+%lld weitere",
        "es": "+%lld más",
        "pl": "+%lld więcej"
    },
    "candidateBar.noPreview": {
        "fr": "Aucun aperçu",
        "de": "Keine Vorschau",
        "es": "Sin vista previa",
        "pl": "Brak podglądu"
    },
    "candidateBar.fileCount": {
        "fr": "%lld fichiers",
        "de": "%lld Dateien",
        "es": "%lld archivos",
        "pl": "Pliki: %lld"
    },
    "candidateBar.emptyText": {
        "fr": "Vide",
        "de": "Leer",
        "es": "Vacío",
        "pl": "Puste"
    }
})

BATCH2["candidateBar.locationFallback"] = {'fr': 'Position du curseur indisponible. Affichage près du pointeur ; vérifiez l’accessibilité.', 'de': 'Cursorposition nicht verfügbar. Anzeige am Mauszeiger; Bedienungshilfen prüfen.', 'es': 'Posición del cursor no disponible. Se muestra junto al puntero; comprueba Accesibilidad.', 'pl': 'Pozycja kursora niedostępna. Wyświetlanie przy wskaźniku; sprawdź dostępność.'}

# Vertical candidate pages and native settings (2026-10-28).
BATCH2.update({
    "settings.group.app": {
        "fr": "Application",
        "de": "App",
        "es": "Aplicación",
        "pl": "Aplikacja"
    },
    "settings.group.data": {
        "fr": "Données",
        "de": "Daten",
        "es": "Datos",
        "pl": "Dane"
    },
    "settings.tab.quickPaste": {
        "fr": "Collage rapide",
        "de": "Schnelles Einfügen",
        "es": "Pegado rápido",
        "pl": "Szybkie wklejanie"
    },
    "clipboard.style.previewTimeline": {
        "fr": "Des cartes en bas de l’écran.",
        "de": "Karten am unteren Bildschirmrand.",
        "es": "Tarjetas en la parte inferior de la pantalla.",
        "pl": "Karty u dołu ekranu."
    },
    "clipboard.style.previewCandidate": {
        "fr": "Une liste près du curseur de texte.",
        "de": "Eine Liste neben dem Textcursor.",
        "es": "Una lista junto al cursor de texto.",
        "pl": "Lista przy kursorze tekstowym."
    },
    "candidatePlacement.title": {
        "fr": "Position des candidats",
        "de": "Position der Kandidaten",
        "es": "Posición de candidatos",
        "pl": "Pozycja kandydatów"
    },
    "candidatePlacement.status": {
        "fr": "Accessibilité",
        "de": "Bedienungshilfen",
        "es": "Accesibilidad",
        "pl": "Dostępność"
    },
    "candidatePlacement.granted": {
        "fr": "Autorisé",
        "de": "Erlaubt",
        "es": "Permitido",
        "pl": "Zezwolono"
    },
    "candidatePlacement.notGranted": {
        "fr": "Non autorisé",
        "de": "Nicht erlaubt",
        "es": "Sin permiso",
        "pl": "Brak uprawnień"
    },
    "candidatePlacement.request": {
        "fr": "Autoriser…",
        "de": "Zugriff erlauben…",
        "es": "Conceder acceso…",
        "pl": "Przyznaj dostęp…"
    },
    "candidatePlacement.help": {
        "fr": "L’accessibilité permet un affichage près du curseur de texte, sinon près du pointeur.",
        "de": "Mit Bedienungshilfen erscheint die Liste am Textcursor, andernfalls am Mauszeiger.",
        "es": "Accesibilidad permite mostrar la lista junto al cursor; si no está disponible, junto al puntero.",
        "pl": "Dostępność pozwala wyświetlać listę przy kursorze tekstowym, a w razie braku pozycji przy wskaźniku."
    },
    "candidateBar.page": {
        "fr": "%lld/%lld",
        "de": "%lld/%lld",
        "es": "%lld/%lld",
        "pl": "%lld/%lld"
    },
    "candidateBar.previousPage": {
        "fr": "Page précédente",
        "de": "Vorherige Seite",
        "es": "Página anterior",
        "pl": "Poprzednia strona"
    },
    "candidateBar.nextPage": {
        "fr": "Page suivante",
        "de": "Nächste Seite",
        "es": "Página siguiente",
        "pl": "Następna strona"
    },
    "settings.tab.ocr": {
        "fr": "OCR",
        "de": "OCR",
        "es": "OCR",
        "pl": "OCR"
    },
    "shortcuts.timelineFootnote": {
        "fr": "⇧⌘C ouvre l’historique. Le collage rapide se configure sur sa propre page.",
        "de": "⇧⌘C öffnet den Verlauf. Schnelles Einfügen hat eine eigene Einstellungsseite.",
        "es": "⇧⌘C abre el historial. El pegado rápido se configura en su propia página.",
        "pl": "⇧⌘C otwiera historię. Szybkie wklejanie ma osobną stronę ustawień."
    },
    "clipboard.style.help": {
        "fr": "10 éléments par page, Tab pour avancer. Le raccourci d’ouverture reste commun.",
        "de": "10 Einträge pro Seite, Tab blättert weiter. Beide Ansichten nutzen denselben Kurzbefehl.",
        "es": "10 elementos por página; Tab avanza. Ambas vistas usan el mismo atajo.",
        "pl": "10 pozycji na stronę; Tab przechodzi dalej. Oba widoki mają ten sam skrót."
    },
    "quickPaste.scopeHelp": {
        "fr": "Seuls les types sélectionnés sont convertis. Les images utilisent la page OCR. Sans accessibilité, collez avec ⌘V. Le presse-papiers est restauré sauf si un nouvel élément a été copié.",
        "de": "Nur ausgewählte Typen werden umgewandelt. Bilder nutzen die OCR-Seite. Ohne Bedienungshilfen manuell mit ⌘V einfügen. Die Zwischenablage wird wiederhergestellt, sofern nichts Neues kopiert wurde.",
        "es": "Solo se convierten los tipos seleccionados. Las imágenes usan la página OCR. Sin Accesibilidad, pega con ⌘V. El portapapeles se restaura salvo que copies algo nuevo.",
        "pl": "Konwertowane są tylko zaznaczone typy. Obrazy korzystają ze strony OCR. Bez Dostępności wklej ręcznie przez ⌘V. Schowek jest przywracany, chyba że skopiowano coś nowego."
    }
})

BATCH2["candidateBar.list"] = {"fr": "Éléments du presse-papiers", "de": "Zwischenablage-Einträge", "es": "Candidatos del portapapeles", "pl": "Pozycje schowka"}


# Local diagnostics only; no product analytics.
BATCH2.update({
    "privacy.logs.title": {
        "fr": "Journaux de diagnostic locaux",
        "de": "Lokale Diagnoseprotokolle",
        "es": "Registros de diagnóstico locales",
        "pl": "Lokalne dzienniki diagnostyczne"
    },
    "privacy.logs.description": {
        "fr": "Aucune information d’utilisation n’est collectée ni envoyée. Les journaux restent sur ce Mac et ne contiennent pas le presse-papiers.",
        "de": "Nutzungsdaten werden weder erfasst noch übertragen. Diagnoseprotokolle bleiben auf diesem Mac und enthalten keine Zwischenablage-Inhalte.",
        "es": "No se recopila ni envía información de uso. Los registros permanecen en este Mac y no contienen el contenido del portapapeles.",
        "pl": "Dane o użytkowaniu nie są zbierane ani wysyłane. Dzienniki pozostają na tym Macu i nie zawierają treści schowka."
    },
    "privacy.logs.retention": {
        "fr": "Conservation maximale : 14 jours, environ 768 Ko.",
        "de": "Aufbewahrung: maximal 14 Tage, insgesamt etwa 768 KB.",
        "es": "Se conservan hasta 14 días, con un total de unos 768 KB.",
        "pl": "Dzienniki są przechowywane do 14 dni, łącznie około 768 KB."
    },
    "privacy.logs.summary": {
        "fr": "%lld fichiers · %@",
        "de": "%lld Dateien · %@",
        "es": "%lld archivos · %@",
        "pl": "%lld plików · %@"
    },
    "privacy.logs.delete": {
        "fr": "Supprimer les anciens journaux",
        "de": "Bisherige Protokolle löschen",
        "es": "Eliminar registros anteriores",
        "pl": "Usuń dotychczasowe dzienniki"
    },
    "privacy.logs.confirmTitle": {
        "fr": "Supprimer les anciens journaux ?",
        "de": "Bisherige Protokolle löschen?",
        "es": "¿Eliminar los registros anteriores?",
        "pl": "Usunąć dotychczasowe dzienniki?"
    },
    "privacy.logs.confirmMessage": {
        "fr": "Seuls les journaux locaux seront supprimés. Réglages, historique et pièces jointes seront conservés.",
        "de": "Nur lokale Diagnoseprotokolle werden gelöscht. Einstellungen, Verlauf und Anhänge bleiben erhalten.",
        "es": "Solo se eliminan los registros locales. Se conservan los ajustes, el historial y los adjuntos.",
        "pl": "Usunięte zostaną tylko lokalne dzienniki. Ustawienia, historia i załączniki pozostaną."
    },
    "privacy.logs.deleted": {
        "fr": "%lld fichiers journaux supprimés.",
        "de": "%lld Protokolldateien gelöscht.",
        "es": "Se eliminaron %lld archivos de registro.",
        "pl": "Usunięto %lld plików dziennika."
    },
    "privacy.logs.failed": {
        "fr": "Accès aux journaux impossible. Réessayez.",
        "de": "Zugriff auf Protokolle fehlgeschlagen. Erneut versuchen.",
        "es": "No se pudo acceder a los registros. Inténtalo de nuevo.",
        "pl": "Nie można uzyskać dostępu do dzienników. Spróbuj ponownie."
    },
    "privacy.logs.footerScope": {
        "fr": "Seuls les journaux locaux de cette app sont effacés. Réglages, historique, pièces jointes et journaux macOS sont conservés.",
        "de": "Nur die lokalen Protokolle dieser App werden gelöscht. Einstellungen, Verlauf, Anhänge und macOS-Systemprotokolle bleiben erhalten.",
        "es": "Solo se borran los registros locales de esta app. Se conservan ajustes, historial, adjuntos y registros del sistema macOS.",
        "pl": "Usuwane są tylko lokalne dzienniki tej aplikacji. Ustawienia, historia, załączniki i dzienniki macOS pozostają."
    }
})

def merge_batch2(strings: dict[str, dict[str, str]]) -> dict[str, dict[str, str]]:
    merged = {key: dict(locs) for key, locs in strings.items()}
    missing = set(merged) - set(BATCH2)
    if missing:
        raise SystemExit(f"Missing batch-2 translations for: {sorted(missing)}")
    extra = set(BATCH2) - set(merged)
    if extra:
        raise SystemExit(f"Unknown batch-2 keys: {sorted(extra)}")
    for key, locs in BATCH2.items():
        merged[key].update(locs)
    return merged
