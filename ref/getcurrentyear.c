// Get the current year, given the 
// number of days since 1 Jan 1980
int GetCurrentYear(int days) {
    int year = 1980;
    while (days > 365) {
        if (IsLeapYear(year)) {
            if (days > 366) {
                days -= 366;
                year += 1;
            }
        }
        else {
            days -= 365;
            year += 1;
        }
    }
    return year;
}