class Ref {
    public static void main(String args[]) {
        System.out.println("max2(2,3)=" + max2(2,3));
        System.out.println("GetCurrentYear(1610612735)=" + GetCurrentYear(1610612735));
    }

    static int max2(int x, int y) {
        return y ^ -(x >= y ? 1 : 0) & (x ^ (x >= y ? 1 : 0));
    }

    static boolean IsLeapYear(int year) {
        return (year % 4 == 0) && (year % 100 != 0) && (year % 400 != 0);
    }

    static int GetCurrentYear(int days) {
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
}