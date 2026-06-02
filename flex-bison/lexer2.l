%{                                    /* Επίπεδο 1: Βιβλιοθήκες και εξωτερικές μεταβλητές */
/* Το σακίδιο με τα εργαλεία: Φωνάζουμε τους φίλους που ξέρουν να διαβάζουν και να μετράνε! */
#include "parser.tab.h" 
#include <stdio.h>      
#include <stdlib.h>     
#include <string.h>     
extern int line_num; /* Κοιτάμε σε ποια γραμμή του βιβλίου είμαστε */
%}



                                             /* Επίπεδο 2: Ρυθμίσεις αναλυτή */
%option noyywrap /* Ρύθμιση: Θα διαβάσουμε μόνο ένα βιβλίο σήμερα! */
%x COMMENT /* Φτιάχνουμε το "Κρυφό Δωμάτιο" για τα μεγάλα σχόλια */



%%

[Cc][Rr][Ee][Aa][Tt][Ee]     { printf("%s", yytext); return CREATE; /* Επίπεδο 3: Δεσμευμένες λέξεις (Keywords) */ /* Τουβλάκι CREATE! */ }
[Tt][Aa][Bb][Ll][Ee]         { printf("%s", yytext); return TABLE; /* σύστημα regex */ /* Τουβλάκι TABLE! */ }
[Ss][Ee][Ll][Ee][Cc][Tt]     { printf("%s", yytext); return SELECT; /* Τουβλάκι SELECT! */ }
[Ff][Rr][Oo][Mm]             { printf("%s", yytext); return FROM; /* Αυτοκόλλητο FROM! */ }
[Ww][Hh][Ee][Rr][Ee]         { printf("%s", yytext); return WHERE; /* Αυτοκόλλητο WHERE! */ }
[Gg][Rr][Oo][Uu][Pp]         { printf("%s", yytext); return GROUP; /* Αυτοκόλλητο GROUP! */ }
[Bb][Yy]                     { printf("%s", yytext); return BY; /* Αυτοκόλλητο BY! */ }
[Oo][Rr][Dd][Ee][Rr]         { printf("%s", yytext); return ORDER; /* Αυτοκόλλητο ORDER! */ }
[Ll][Ii][Mm][Ii][Tt]         { printf("%s", yytext); return LIMIT; /* Αυτοκόλλητο LIMIT! */ }
[Jj][Oo][Ii][Nn]             { printf("%s", yytext); return JOIN; /* Αυτοκόλλητο JOIN! */ }
[Oo][Nn]                     { printf("%s", yytext); return ON; /* Αυτοκόλλητο ON! */ }
[Aa][Ss]                     { printf("%s", yytext); return AS; /* Αυτοκόλλητο AS! */ }



[Ii][Nn][Tt]                 { printf("%s", yytext); return TYPE_INT; /* Επίπεδο 4: Τύποι δεδομένων και λογικοί τελεστές */ /* Μόνο ολόκληροι αριθμοί */ }
[Ff][Ll][Oo][Aa][Tt]         { printf("%s", yytext); return TYPE_FLOAT; /* Αριθμοί με τελεία/δεκαδικοί */ }
[Vv][Aa][Rr][Cc][Hh][Aa][Rr] { printf("%s", yytext); return TYPE_VARCHAR; /* Κείμενο ή λέξεις */ }
[Aa][Nn][Dd]                 { printf("%s", yytext); return AND; /* Λογικό ΚΑΙ */ }
[Oo][Rr]                     { printf("%s", yytext); return OR; /* Λογικό Ή */ }
[Nn][Oo][Tt]                 { printf("%s", yytext); return NOT; /* Λογικό ΟΧΙ */ }
[Ii][Nn]                     { printf("%s", yytext); return IN; /* Λογικό ΜΕΣΑ ΣΕ */ }



"=" { printf("%s", yytext); return EQUALS; /* Επίπεδο 5: Τελεστές σύγκρισης και σύμβολα στίξης */ /* Σύμβολο ΙΣΟΝ */ }
"!=" { printf("%s", yytext); return NOT_EQUALS; /* Σύμβολο ΔΙΑΦΟΡΟ */ }
">=" { printf("%s", yytext); return GREATER_EQUAL; /* Μεγαλύτερο ή ίσο */ }
"<=" { printf("%s", yytext); return LESS_EQUAL; /* Μικρότερο ή ίσο */ }
">" { printf("%s", yytext); return GREATER; /* Σκέτο Μεγαλύτερο */ }
"<" { printf("%s", yytext); return LESS; /* Σκέτο Μικρότερο */ }
"," { printf("%s", yytext); return COMMA; /* Κόμμα */ }
";" { printf("%s", yytext); return SEMICOLON; /* Ερωτηματικό για το τέλος της πρότασης */ }
"." { printf("%s", yytext); return DOT; /* Τελεία */ }
"(" { printf("%s", yytext); return LPAREN; /* Ανοιχτή παρένθεση */ }
")" { printf("%s", yytext); return RPAREN; /* Κλειστή παρένθεση */ }
"*" { printf("%s", yytext); return ASTERISK; /* (↓)Επίπεδο 6: Αναγνώριση αριθμών, συμβολοσειρών και αναγνωριστικών */ /* Αστεράκι για όλα τα παιχνίδια */ }



[0-9]+\.[0-9]+ { printf("%s", yytext); yylval.fval = atof(yytext); return FLOAT_VAL; /* Βρήκα δεκαδικό αριθμό, τον βάζω στο σακίδιο */ }
[0-9]+ { printf("%s", yytext); yylval.ival = atoi(yytext); return INT_VAL; /* Βρήκα ολόκληρο αριθμό, τον βάζω στο σακίδιο */ }
"'"[^']*"'" { printf("%s", yytext); yylval.sval = strdup(yytext); return STRING_VAL; /* Βρήκα λέξη σε εισαγωγικά, την αντιγράφω στο σακίδιο */ }
[a-zA-Z_][a-zA-Z0-9_]* { printf("%s", yytext); yylval.sval = strdup(yytext); return IDENTIFIER; /* Βρήκα ένα κανονικό όνομα, το βάζω στο σακίδιο */ }



"--"[^\n]* { printf("%s", yytext); /* Επίπεδο 7: Διαχείριση σχολίων */ /* Σχόλιο μίας γραμμής: το τυπώνω αλλά δεν στέλνω τουβλάκι */ }
"/*" { BEGIN(COMMENT); printf("%s", yytext); /* Μπαίνω στο κρυφό δωμάτιο των σχολίων */ }
<COMMENT>"*/" { BEGIN(INITIAL); printf("%s", yytext); /* Βγαίνω από το κρυφό δωμάτιο */ }
<COMMENT>\n { line_num++; printf("%s", yytext); /* Ανεβαίνω όροφο μέσα στο κρυφό δωμάτιο */ }
<COMMENT>. { printf("%s", yytext); /* Οτιδήποτε άλλο μέσα στο κρυφό δωμάτιο, απλά το τυπώνω */ }



[ \t\r]+ { printf("%s", yytext); } /* Επίπεδο 8: Κενά διαστήματα, αλλαγές γραμμής και χειρισμός σφαλμάτων */ /* Αγνοώ τον αέρα ανάμεσα στις λέξεις */
\n { printf("%s", yytext); line_num++; /* Αλλαγή γραμμής: ανεβαίνω όροφο στο κανονικό παιχνίδι */ } 
. { printf("%s", yytext); fprintf(stderr, "\n[Λεκτικό Σφάλμα] Άγνωστος χαρακτήρας '%s' στη γραμμή %d\n", yytext, line_num); exit(1); /* Άγνωστος χαρακτήρας: βάζω τα κλάματα και σταματάω! */ }
%%