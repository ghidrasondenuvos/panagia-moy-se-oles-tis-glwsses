/* =========================================================================
   ΕΠΙΠΕΔΟ 1: ΒΙΒΛΙΟΘΗΚΕΣ ΚΑΙ ΓΕΝΙΚΕΣ ΔΗΛΩΣΕΙΣ
   ========================================================================= */
%{
/* Φωνάζουμε 3 έξυπνους φίλους μας που ξέρουν να κάνουν ειδικά πράγματα: */
#include <stdio.h>   // Ο φίλος που ξέρει να γράφει και να διαβάζει μηνύματα.
#include <stdlib.h>  // Ο φίλος που ξέρει να μας δίνει άδεια κουτιά στη μνήμη.
#include <string.h>  // Ο φίλος που συγκρίνει λέξεις.
#include <windows.h> // Ο φίλος που φτιάχνει την κονσόλα στα Windows.
#undef IN            // Πετάμε έναν κανόνα των Windows που μας μπερδεύει!

void yyerror(const char *s); /* Λέμε στο ρομπότ ότι θα έχουμε μια φωνή για τα λάθη */
int yylex(void);             /* Το βοηθάκι που δίνει μία-μία τις λέξεις */
int line_num = 1;            /* Μετρητής για το ποια γραμμή διαβάζουμε */
%}

/* =========================================================================
   ΕΠΙΠΕΔΟ 2: ΔΟΜΕΣ ΔΕΔΟΜΕΝΩΝ ΚΑΙ ΣΗΜΑΣΙΟΛΟΓΙΚΟΙ ΕΛΕΓΧΟΙ
   ========================================================================= */
%{
#define MAX_TABLES 50        /* Κανόνας: Το πολύ 50 μεγάλα κουτιά (πίνακες) */
#define MAX_COLUMNS 50       /* Κανόνας: Κάθε μεγάλο κουτί χωράει 50 μικρά κουτάκια (στήλες) */
#define MAX_USED_COLUMNS 100 /* Κανόνας: Θυμόμαστε μέχρι 100 αυτοκόλλητα μαζί */

/* Φτιάχνουμε ένα μαγικό μεγεθυντικό φακό για να βλέπουμε αν δύο λέξεις είναι ίδιες... */
int icmp(const char *s1, const char *s2) {
    while (*s1 && *s2) {
        char c1 = *s1;
        char c2 = *s2;
        // Αν είναι κεφαλαίο γράμμα, το κάνουμε μικρό στο μυαλό μας.
        if (c1 >= 'A' && c1 <= 'Z') c1 = c1 - 'A' + 'a';
        if (c2 >= 'A' && c2 <= 'Z') c2 = c2 - 'A' + 'a';
        if (c1 != c2) return c1 - c2; // Αν δεν ταιριάζουν, σταματάμε!
        s1++; s2++;
    }
    char c1 = *s1;
    char c2 = *s2;
    if (c1 >= 'A' && c1 <= 'Z') c1 = c1 - 'A' + 'a';
    if (c2 >= 'A' && c2 <= 'Z') c2 = c2 - 'A' + 'a';
    return c1 - c2;
}

/* Ορισμός δομών για τη διαχείριση της βάσης δεδομένων (Τα παιχνίδια) */
typedef struct {
    char name[50]; // Το όνομα της στήλης
    int type;      // 1: INT (αριθμοί), 2: FLOAT (δεκαδικοί), 3: VARCHAR (γράμματα)
} Column;

/* Σχεδιάζουμε πώς είναι ένας "Πίνακας": Ένα μεγάλο κουτί που έχει μικρά κουτάκια μέσα */
typedef struct {
    char name[50];             
    Column columns[MAX_COLUMNS];
    int col_count;
} Table;

/* Το μεγάλο Ντουλάπι! Εδώ κλειδώνουμε όλους τους πίνακες */
Table symbol_table[MAX_TABLES];
int table_count = 0; 

/* Πρόχειρα χαρτιά για να σημειώνουμε την ώρα που φτιάχνουμε έναν πίνακα */
char current_table_name[50];
Column temp_columns[MAX_COLUMNS];  
int temp_col_count = 0;

/* Κουτάκι "Ενεργός Πίνακας": Ποιον χρησιμοποιούμε τώρα και ποιο είναι το κρυφό του όνομα (Alias) */
typedef struct {
    char table_name[50]; 
    char alias_name[50]; 
} ActiveTable;

/* Λίστα για τους πίνακες που ανοίξαμε πάνω στο χαλί για να παίξουμε */
ActiveTable active_tables[MAX_TABLES];
int active_table_count = 0;

/* Λίστα για να γράφουμε ποιες στήλες ζήτησε το παιδί */
typedef struct {
    char table_or_alias[50];
    char col_name[50];       
    int line;
} UsedColumn;

UsedColumn used_columns[MAX_USED_COLUMNS];
int used_column_count = 0;

/* Πρόχειρος κουμπαράς για τους τύπους δεδομένων στη λίστα "IN" */
int current_in_types[100];
int current_in_count = 0;

/* Συναρτήσεις αναζήτησης στον πίνακα συμβόλων (Ψάχνουμε στο Ντουλάπι!) */
int find_table(const char *name) {
    for (int i = 0; i < table_count; i++) {
        if (icmp(symbol_table[i].name, name) == 0) return i; // Τον βρήκαμε!
    }
    return -1; 
}

/* Ψάχνει μέσα σε ένα συγκεκριμένο μεγάλο κουτί να δει αν υπάρχει το μικρό κουτάκι */
int find_column_in_table(int table_idx, const char *col_name) {
    if (table_idx < 0 || table_idx >= table_count) return -1;
    for (int i = 0; i < symbol_table[table_idx].col_count; i++) {
        if (icmp(symbol_table[table_idx].columns[i].name, col_name) == 0) {
            return symbol_table[table_idx].columns[i].type; // Βρήκαμε τον τύπο του!
        }
    }
    return -1;
}

/* Μας λέει ποιο είναι το αληθινό όνομα πίσω από ένα χαϊδευτικό (alias) */
int resolve_active_table(const char *name_or_alias) {
    for (int i = 0; i < active_table_count; i++) {
        if (icmp(active_tables[i].alias_name, name_or_alias) == 0 ||
            icmp(active_tables[i].table_name, name_or_alias) == 0) {
            return find_table(active_tables[i].table_name);
        }
    }
    return -1;
}
%}

/* =========================================================================
   ΕΠΙΠΕΔΟ 3: ΟΡΙΣΜΟΣ ΤΥΠΩΝ ΚΑΙ TOKENS
   ========================================================================= */
%code requires {
    /* Ειδική ταυτότητα για τις στήλες ώστε να μην μπερδεύεται το ρομπότ */
    typedef struct {
        char table_or_alias[50];
        char col_name[50];
    } ColumnRef;
}

%union {
    int ival;        /* Ο σάκος μπορεί να κρατήσει έναν κανονικό αριθμό */
    float fval;      /* Ή έναν δεκαδικό */
    char *sval;      /* Ή μια λέξη */
    ColumnRef col;   /* Ή μια στήλη με τον πίνακα της */
    int type_val;    /* Ή έναν κωδικό τύπου */
}

%token CREATE TABLE SELECT FROM WHERE GROUP BY ORDER LIMIT JOIN ON AS
%token TYPE_INT TYPE_FLOAT TYPE_VARCHAR
%token AND OR NOT IN
%token EQUALS NOT_EQUALS GREATER_EQUAL LESS_EQUAL GREATER LESS
%token COMMA SEMICOLON DOT LPAREN RPAREN ASTERISK

%token <ival> INT_VAL
%token <fval> FLOAT_VAL
%token <sval> STRING_VAL IDENTIFIER

%type <col> column_item
%type <type_val> data_type literal

/* Λέμε ποια λογικά τουβλάκια είναι πιο δυνατά από τα άλλα */
%left OR
%left AND
%right NOT

%%

/* =========================================================================
   ΕΠΙΠΕΔΟ 4: ΓΡΑΜΜΑΤΙΚΗ ΥΨΗΛΟΥ ΕΠΙΠΕΔΟΥ
   ========================================================================= */
program:
    statements /* Το πρόγραμμα είναι απλά μια στοίβα από εντολές */
    ;
statements:
    statement /* Μία εντολή... */
    | statements statement /* ...ή πολλές μαζί */
    ;
statement:
    create_table_stmt /* "Φτιάξε Κουτί" */
    | select_stmt /* "Διάλεξε Παιχνίδια" */
    ;
/* =========================================================================
   ΕΠΙΠΕΔΟ 5: ΥΛΟΠΟΙΗΣΗ ΕΝΤΟΛΗΣ CREATE TABLE
   ========================================================================= */
create_table_stmt:
    CREATE TABLE IDENTIFIER {
        /* Μόλις δούμε το όνομα, ελέγχουμε αν υπάρχει ήδη στο ντουλάπι */
        if (find_table($3) != -1) {
            fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Ο πίνακας '%s' υπάρχει ήδη.\n", line_num, $3);
            exit(1); /* Ζαβολιά! Το ρομπότ σταματάει το παιχνίδι! */
        }
        strcpy(current_table_name, $3); /* Σημειώνουμε το όνομα του νέου πίνακα */
        temp_col_count = 0; /* Μηδενίζουμε τις πρόχειρες στήλες */
        free($3);
    } LPAREN create_col_list RPAREN SEMICOLON {
        /* Βάζουμε τον πίνακα στο μεγάλο ντουλάπι! */
        strcpy(symbol_table[table_count].name, current_table_name);
        symbol_table[table_count].col_count = temp_col_count;
        for (int i = 0; i < temp_col_count; i++) {
            symbol_table[table_count].columns[i] = temp_columns[i];
        }
        table_count++; 
        printf("\n[OK] Δημιουργήθηκε ο πίνακας '%s'.\n\n", current_table_name);
    }
    ;
create_col_list:
    create_col_def
    | create_col_list COMMA create_col_def /* Πολλές στήλες χωρισμένες με κόμμα */
    ;
create_col_def:
    IDENTIFIER data_type {
        /* Ελέγχουμε αν βάλαμε κατά λάθος δύο φορές την ίδια στήλη στο ίδιο κουτί! */
        for (int i = 0; i < temp_col_count; i++) {
            if (icmp(temp_columns[i].name, $1) == 0) {
                fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' ορίζεται δύο φορές στον πίνακα '%s'.\n", line_num, $1, current_table_name);
                exit(1);
            }
        }
        strcpy(temp_columns[temp_col_count].name, $1);
        temp_columns[temp_col_count].type = $2;
        temp_col_count++;
        free($1);
    }
    ;

data_type:
    TYPE_INT { $$ = 1; /* Κωδικός 1: Ολόκληροι αριθμοί (π.χ. 5 στρατιωτάκια) */
}
    | TYPE_FLOAT { $$ = 2; /* Κωδικός 2: Αριθμοί με τελεία (π.χ. 2.5 κιλά) */ }
    |
TYPE_VARCHAR LPAREN INT_VAL RPAREN {
        /* Κωδικός 3: Λέξεις. Το μέγεθος της λέξης πρέπει να είναι θετικό! */
        if ($3 <= 0) {
            fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Το μέγεθος του VARCHAR πρέπει να είναι > 0.\n", line_num);
            exit(1);
        }
        $$ = 3;
    }
    ;
/* =========================================================================
   ΕΠΙΠΕΔΟ 6: ΥΛΟΠΟΙΗΣΗ SELECT ΚΑΙ ΔΙΑΧΕΙΡΙΣΗ ΠΙΝΑΚΩΝ
   ========================================================================= */
select_stmt:
    SELECT { 
        /* Καθαρίζουμε τις λίστες για να γράψουμε καινούργια πράγματα */
        used_column_count = 0;
        active_table_count = 0; 
    } 
    select_col_list FROM table_ref join_clause_list where_clause group_by_clause order_by_clause limit_clause SEMICOLON {
        
        /* ΤΩΡΑ ΤΟ ΡΟΜΠΟΤ ΚΑΝΕΙ ΤΟΝ ΜΕΓΑΛΟ ΕΛΕΓΧΟ ΣΕ ΟΛΕΣ ΤΙΣ ΣΤΗΛΕΣ! */
        for (int i = 0; i < used_column_count; i++) {
            char *prefix = used_columns[i].table_or_alias;
            char *cname = used_columns[i].col_name;       
            int line = used_columns[i].line;              
            int t_idx = -1;
            if (strlen(prefix) > 0) {
                int match_idx = -1;
                for (int j = 0; j < active_table_count; j++) {
                    if (icmp(active_tables[j].alias_name, prefix) == 0) {
                        match_idx = j;
                        break;
                    }
                }
                
                /* Αν δε βρούμε το alias, κοιτάμε αν έγραψε το αληθινό όνομα ενώ είχε alias! */
                if (match_idx == -1) {
                    for (int j = 0; j < active_table_count; j++) {
                  
                        if (icmp(active_tables[j].table_name, prefix) == 0) {
                            if (icmp(active_tables[j].table_name, active_tables[j].alias_name) != 0) {
                                fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Πρέπει να χρησιμοποιηθεί το alias '%s' αντί για το όνομα του πίνακα '%s'.\n", line, active_tables[j].alias_name, prefix);
                                exit(1);
                            }
                            match_idx = j;
                            break;
                        }
                    }
                }
                
                if (match_idx == -1) {
                    fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Ο πίνακας ή το alias '%s' δεν συμμετέχει στο ερώτημα.\n", line, prefix);
                    exit(1); /* Αυτός ο πίνακας δεν είναι καν ανοιχτός στο χαλί! */
                }
                t_idx = find_table(active_tables[match_idx].table_name);
            } else {
                /* Αν γράψαμε τη στήλη σκέτη (χωρίς τελεία) */
                int matches = 0;
                int requires_alias = 0;
                char req_alias_name[50] = "";
                for (int j = 0; j < active_table_count; j++) {
                    int tmp = find_table(active_tables[j].table_name);
                    if (find_column_in_table(tmp, cname) != -1) {
                        t_idx = tmp;
                        matches++;
                        if (icmp(active_tables[j].table_name, active_tables[j].alias_name) != 0) {
                            requires_alias = 1;
                            strcpy(req_alias_name, active_tables[j].alias_name);
                        }
                    }
                }
                
                if (matches == 0) {
                    fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' δεν ανήκει στους επιλεγμένους πίνακες.\n", line, cname);
                    exit(1);
                }
                if (matches > 1) {
                    fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' είναι ασαφής.\n", line, cname);
                    exit(1); /* Υπάρχει σε 2 πίνακες και μπερδευτήκαμε! */
                }
                if (requires_alias) {
                    fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' πρέπει υποχρεωτικά να έχει το πρόθεμα του alias '%s'.\n", line, cname, req_alias_name);
                    exit(1);
                }
            }
            
            /* Υπάρχει πράγματι αυτή η στήλη μέσα στο μεγάλο κουτί στο ντουλάπι; */
            if (find_column_in_table(t_idx, cname) == -1) {
                fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' δεν υπάρχει στον πίνακα '%s'.\n", line, cname, symbol_table[t_idx].name);
                exit(1);
            }
        }
        printf("\n[OK] Επιτυχής αναγνώριση και έλεγχος εντολής SELECT.\n\n");
    }
    ;

select_col_list:
    ASTERISK /* Αστεράκι σημαίνει "όλα τα παιχνίδια" */
    | column_list
    ;
column_list:
    column_item
    | column_list COMMA column_item
    ;
column_item:
    IDENTIFIER {
        strcpy($$.table_or_alias, "");
        strcpy($$.col_name, $1);
        /* Τη γράφουμε στη λίστα για να την ελέγξει το ρομπότ στο τέλος */
        strcpy(used_columns[used_column_count].table_or_alias, "");
        strcpy(used_columns[used_column_count].col_name, $1);
        used_columns[used_column_count].line = line_num;
        used_column_count++;
        free($1);
    }
    |
    IDENTIFIER DOT IDENTIFIER {
        strcpy($$.table_or_alias, $1);
        strcpy($$.col_name, $3);
        strcpy(used_columns[used_column_count].table_or_alias, $1);
        strcpy(used_columns[used_column_count].col_name, $3);
        used_columns[used_column_count].line = line_num;
        used_column_count++;
        free($1); free($3);
    }
    ;
table_ref:
    IDENTIFIER {
        int idx = find_table($1);
        if (idx == -1) {
            fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Ο πίνακας '%s' δεν έχει δημιουργηθεί.\n", line_num, $1);
            exit(1); /* Πάμε να παίξουμε με κουτί που δεν φτιάξαμε ποτέ! Λάθος! */
        }
        strcpy(active_tables[active_table_count].table_name, $1);
        strcpy(active_tables[active_table_count].alias_name, $1);
        active_table_count++;
        free($1);
    }
    |
    IDENTIFIER AS IDENTIFIER {
        /* FROM Students AS s: αληθινό=Students, χαϊδευτικό=s */
        int idx = find_table($1);
        if (idx == -1) {
            fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Ο πίνακας '%s' δεν έχει δημιουργηθεί.\n", line_num, $1);
            exit(1);
        }
        strcpy(active_tables[active_table_count].table_name, $1);
        strcpy(active_tables[active_table_count].alias_name, $3);
        active_table_count++;
        free($1); free($3);
    }
    | IDENTIFIER IDENTIFIER {
        int idx = find_table($1);
        if (idx == -1) {
            fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Ο πίνακας '%s' δεν έχει δημιουργηθεί.\n", line_num, $1);
            exit(1);
        }
        strcpy(active_tables[active_table_count].table_name, $1);
        strcpy(active_tables[active_table_count].alias_name, $2);
        active_table_count++;
        free($1); free($2);
    }
    ;

/* =========================================================================
   ΕΠΙΠΕΔΟ 7: ΣΥΝΘΗΚΕΣ, ΦΙΛΤΡΑΡΙΣΜΑ ΚΑΙ ΛΟΙΠΕΣ ΛΕΙΤΟΥΡΓΙΕΣ
   ========================================================================= */
join_clause_list:
    %empty
    |
    join_clause_list join_clause
    ;

join_clause:
    JOIN table_ref ON column_item EQUALS column_item /* Ενώνει 2 πίνακες */
    ;
where_clause:
    %empty
    | WHERE condition /* Φιλτράρουμε τα παιχνίδια */
    ;
condition:
    column_item rel_op literal {
        int t_idx = -1;
        if (strlen($1.table_or_alias) > 0) {
            t_idx = resolve_active_table($1.table_or_alias);
        } else {
            for (int j = 0; j < active_table_count; j++) {
                int tmp = find_table(active_tables[j].table_name);
                if (find_column_in_table(tmp, $1.col_name) != -1) t_idx = tmp;
            }
        }
        
        /* ΕΛΕΓΧΟΣ ΣΥΜΒΑΤΟΤΗΤΑΣ: Ταιριάζουν τα παιχνίδια; */
        if (t_idx != -1) {
            int col_type = find_column_in_table(t_idx, $1.col_name);
            int lit_type = $3;                                      
            /* Αν θέλει αριθμό (INT) και δώσουμε γράμματα, το ρομπότ φωνάζει! */
            if (col_type == 1 && lit_type != 1) {
                fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' είναι INT.\n", line_num, $1.col_name);
                exit(1);
            }
            if (col_type == 2 && (lit_type != 1 && lit_type != 2)) {
                fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' είναι FLOAT.\n", line_num, $1.col_name);
                exit(1);
            }
            if (col_type == 3 && lit_type != 3) {
                fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Η στήλη '%s' είναι VARCHAR.\n", line_num, $1.col_name);
                exit(1);
            }
        }
    }
    |
    column_item IN LPAREN literal_list RPAREN {
        /* Έλεγχος αν όλα μέσα στην παρένθεση IN ταιριάζουν με τη στήλη */
        int t_idx = -1;
        if (strlen($1.table_or_alias) > 0) t_idx = resolve_active_table($1.table_or_alias);
        else {
            for (int j = 0; j < active_table_count; j++) {
                int tmp = find_table(active_tables[j].table_name);
                if (find_column_in_table(tmp, $1.col_name) != -1) t_idx = tmp;
            }
        }
        
        if (t_idx != -1) {
            int col_type = find_column_in_table(t_idx, $1.col_name);
            for (int k = 0; k < current_in_count; k++) {
                int lit_type = current_in_types[k];
                if ((col_type == 1 && lit_type != 1) || 
                    (col_type == 2 && (lit_type != 1 && lit_type != 2)) || 
                    (col_type == 3 && lit_type != 3)) {
                    fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Ασύμβατος τύπος στη λίστα του IN 
για τη στήλη '%s'.\n", line_num, $1.col_name);
                    exit(1);
                }
            }
        }
    }
    |
    column_item NOT IN LPAREN literal_list RPAREN {
        /* Το ίδιο με το IN, αλλά για το NOT IN */
        int t_idx = -1;
        if (strlen($1.table_or_alias) > 0) t_idx = resolve_active_table($1.table_or_alias);
        else {
            for (int j = 0; j < active_table_count; j++) {
                int tmp = find_table(active_tables[j].table_name);
                if (find_column_in_table(tmp, $1.col_name) != -1) t_idx = tmp;
            }
        }
        
        if (t_idx != -1) {
            int col_type = find_column_in_table(t_idx, $1.col_name);
            for (int k = 0; k < current_in_count; k++) {
                int lit_type = current_in_types[k];
                if ((col_type == 1 && lit_type != 1) || 
                    (col_type == 2 && (lit_type != 1 && lit_type != 2)) || 
                    (col_type == 3 && lit_type != 3)) {
                    fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Ασύμβατος τύπος στη λίστα του NOT 
IN για τη στήλη '%s'.\n", line_num, $1.col_name);
                    exit(1);
                }
            }
        }
    }
    |
    condition AND condition /* Τουβλάκι AND (ΚΑΙ) */
    | condition OR condition /* Τουβλάκι OR (Ή) */ 
    |
    NOT condition /* Τουβλάκι NOT (ΟΧΙ) */          
    |
    LPAREN condition RPAREN /* Παρένθεση */
    ;

rel_op:
    EQUALS | NOT_EQUALS | GREATER_EQUAL |
    LESS_EQUAL |
    GREATER | LESS
    ;

literal:
    INT_VAL { $$ = 1; /* Επιστρέφει 1 (Ακέραιος) */
}
    | FLOAT_VAL { $$ = 2; /* Επιστρέφει 2 (Δεκαδικός) */ }
    | STRING_VAL { $$ = 3; /* Επιστρέφει 3 (Λέξη) */
free($1); } 
    ;

literal_list:
    literal {
        current_in_count = 0;
        current_in_types[current_in_count++] = $1; /* Βάζουμε την 1η τιμή στον κουμπαρά */
    }
    | literal_list COMMA literal {
        current_in_types[current_in_count++] = $3; /* Προσθέτουμε κι άλλες τιμές */
}
    ;

group_by_clause:
    %empty
    |
    GROUP BY column_list
    ;

order_by_clause:
    %empty
    |
    ORDER BY column_list
    ;

limit_clause:
    %empty
    |
    LIMIT INT_VAL {
        /* Το όριο πρέπει να είναι θετικός αριθμός! Δεν μπορείς να ζητήσεις -5 παιχνίδια */
        if ($2 <= 0) {
            fprintf(stderr, "\n[Σημασιολογικό Σφάλμα] Στη γραμμή %d: Το όριο LIMIT πρέπει να είναι > 0.\n", line_num);
            exit(1);
        }
    }
    ;
/* =========================================================================
   ΕΠΙΠΕΔΟ 8: ΛΕΙΤΟΥΡΓΙΑ ΣΦΑΛΜΑΤΩΝ ΚΑΙ MAIN
   ========================================================================= */
%%

/* Η συνάρτηση που φωνάζει όταν βρούμε συντακτικό λάθος! */
void yyerror(const char *s) {
    fprintf(stderr, "\n\n[Συντακτικό Σφάλμα] στη γραμμή %d: %s\n", line_num, s);
    exit(1); /* Το παιχνίδι κλείνει με κλάματα! */
}

/* Το κουμπί ON του ρομπότ */
int main(int argc, char *argv[]) {
    SetConsoleOutputCP(CP_UTF8); /* Φτιάχνουμε τα ελληνικά στην κονσόλα των Windows! */
    if (argc < 2) {
        fprintf(stderr, "Χρήση: %s <όνομα_αρχείου>\n", argv[0]);
        return 1; /* Ξεχάσαμε να του δώσουμε το βιβλίο! */
}

    FILE *file = fopen(argv[1], "r");
    if (!file) {
        fprintf(stderr, "Σφάλμα: Αδυναμία ανοίγματος του αρχείου '%s'\n", argv[1]);
        return 1;
    }

    extern FILE *yyin;
    yyin = file;
    printf("--- Έναρξη Ανάλυσης Αρχείου ---\n");
    yyparse(); /* Λέμε στο ρομπότ: 'Ξεκίνα να διαβάζεις!' */
    printf("--- Τέλος Ανάλυσης (Όλα OK!) ---\n");
    fclose(file); 
    return 0; /* Το ρομπότ είναι χαρούμενο! */
}