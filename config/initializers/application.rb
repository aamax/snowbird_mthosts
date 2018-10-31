DAYNAMES = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']

MEETINGS = { 'M1' => '2018-10-27', 'M2' => '2018-11-03', 'M3' => '2018-12-09', 'M4' => '2019-02-02' }

HOLIDAYS = [Date.new(2018,12,24),
            Date.new(2018,12,25),
            Date.new(2018,12,31),
            Date.new(2019,1,1),
            Date.new(2019,1,21),
            Date.new(2019,2,18)]

ROOKIE_TOUR_DATE = Date.parse("2019-02-01")

MAX_SURVEY_COUNT = 5

MAX_EMAIL = 'aamaxworks@gmail.com'
COTTER_EMAIL = 'jecotterii@gmail.com'
KATE_EMAIL = 'kmcguinness@snowbird.com'

TOUR_TYPES = %w[P1friday P1weekday P1weekend P2friday P2weekday P2weekend P3friday
                  P3weekday P3weekend P4friday P4weekday P4weekend]
NON_TOUR_TYPES = %w[A1 C1weekend C2weekend C3weekend C4weekend F1weekend F2weekend
                      F3weekend F4weekend G1friday G1weekend G2friday G2weekend G3friday
                      G3weekend G4friday G4weekend H1friday H1weekday H1weekend
                      H2weekend H3weekend H4weekend M1 M2 M3 M4 Race SE SH ST SV T1 T2
                      T3 T4 TL TLT TR]
