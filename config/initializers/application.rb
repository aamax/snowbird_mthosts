DAYNAMES = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']

MEETINGS = { 'M1' => '2022-10-29', 'M2' => '2022-11-05', 'M4' => '2023-02-04' }

HOLIDAYS = [Date.new(2022,12,24),
            Date.new(2022,12,25),
            Date.new(2022,12,31),
            Date.new(2023,1,1),
            Date.new(2023,1,16),
            Date.new(2023,2,20)]

ROOKIE_TOUR_DATE = Date.new(2023,02,01)

OGOMT_FAKE_DATE = '2019-11-01'

# MAX_SURVEY_COUNT = 5

MAX_EMAIL = 'aamaxworks@gmail.com'
COTTER_EMAIL = 'aamaxworks@gmail.com' # override for now to myself
SUPERVISOR_EMAIL = 'bfessler@snowbird.com'

# KATE_EMAIL = 'kmcguinness@snowbird.com'

DEFAULT_PASSWORD = "'5teep&Deep22'"

TOUR_TYPES = %w[P1weekend P1weekday P2weekend P2weekday P3weekend
                  P3weekday P4weekend P4weekday]

NON_TOUR_TYPES = %w[C1weekend C2weekend
                      G1weekend G2weekend G3weekend G4weekend
                      H1weekend H2weekend H3weekend H4weekend
                      M1 M2 M3 M4 TL A1 TR T1 T2 T3 T4
                      G1weekday G2weekday G3weekday
                      H1weekday H2weekday]

TRAINING_TYPES = %w[T1 T2 T3 T4]

HAULER_RIDERS = 13 # total without driver

# SHIFT_TARGET = 19
# A1_COUNT = 7
# OC_COUNT = 10