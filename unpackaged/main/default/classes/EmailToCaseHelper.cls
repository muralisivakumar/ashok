public class EmailToCaseHelper {
    public static String parseHeaderValue(String headers, String key) {
        if (String.isEmpty(headers) || String.isEmpty(key)) return null;

        // Convert key to lowercase for case-insensitive comparison
        String lowerCaseKey = key.toLowerCase();

        for (String line : headers.split('\n')) {
            // Convert line to lowercase for case-insensitive comparison
            if (line.toLowerCase().startsWith(lowerCaseKey + ':')) {
                // Extract the value after the key and return it
                return line.substringAfter(':').trim();
            }
        }
        return null;
    }
}