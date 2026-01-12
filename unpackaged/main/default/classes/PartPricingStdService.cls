public with sharing class PartPricingStdService {
    // Your org: QuoteLineItem.UnitPrice is COST (not sales)
    private static final Boolean UNITPRICE_IS_COST = true;

    // ---------- DTOs ----------
    public class WindowKpi {
        @AuraEnabled public Decimal units = 0;
        @AuraEnabled public Decimal revenue = 0;       // sum of EXT (Sales × Qty)
        @AuraEnabled public Decimal avgUnitPrice = 0;  // qty-weighted Avg Unit COST (varcpq__Unit_Cost__c)
        @AuraEnabled public Decimal lastPrice;         // latest Sales/unit inside bucket (kept for completeness)
        @AuraEnabled public Decimal avgMarginPct;      // revenue-weighted margin %
        @AuraEnabled public Date    lastDate;          // latest sale date in bucket
        // accumulators
        Decimal extSum = 0;
        Decimal marginExtSum = 0;
        Decimal costQtySum = 0;                        // Σ(UnitCost × Qty)
    }
    public class TxnRow {
        @AuraEnabled public DateTime dt;
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String quoteNumber;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Decimal qty;
        @AuraEnabled public Decimal unitPrice;   // Sales price per unit (customer pays)
        @AuraEnabled public Decimal extPrice;    // Revenue (Sales × Qty)
        @AuraEnabled public Decimal unitCost;    // Distributor cost per unit (varcpq__Unit_Cost__c or UnitPrice)
        @AuraEnabled public Decimal marginPct;   // 0..1 (from field when present)
        @AuraEnabled public String pricebookName;
        @AuraEnabled public String currencyIso;
    }
    public class AccountSummary {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public TxnRow latest;
        @AuraEnabled public WindowKpi currentMonth;
        @AuraEnabled public WindowKpi lastMonth;
        @AuraEnabled public WindowKpi priorQ1;
        @AuraEnabled public WindowKpi priorQ2;
        @AuraEnabled public WindowKpi priorQ3;
        @AuraEnabled public WindowKpi ytd;
        @AuraEnabled public WindowKpi lastYear;
        @AuraEnabled public WindowKpi lastToLastYear;
        @AuraEnabled public WindowKpi lifetime;
    }
    public class Summary {
        @AuraEnabled public WindowKpi currentMonth;
        @AuraEnabled public WindowKpi lastMonth;
        @AuraEnabled public WindowKpi priorQ1;
        @AuraEnabled public WindowKpi priorQ2;
        @AuraEnabled public WindowKpi priorQ3;
        @AuraEnabled public WindowKpi ytd;
        @AuraEnabled public WindowKpi lastYear;
        @AuraEnabled public WindowKpi lastToLastYear;
        @AuraEnabled public WindowKpi lifetime;
        @AuraEnabled public TxnRow latest;
        @AuraEnabled public Decimal p25;
        @AuraEnabled public Decimal p50;
        @AuraEnabled public Decimal p75;
        @AuraEnabled public List<TxnRow> transactions;
        @AuraEnabled public List<AccountSummary> accounts;
    }

    // percentile helper
    private class ValWeight implements Comparable {
        Decimal val; Decimal w;
        ValWeight(Decimal v, Decimal weight){ this.val = (v==null?0:v); this.w=(weight==null?0:weight); }
        public Integer compareTo(Object o){
            ValWeight other=(ValWeight)o;
            if(this.val==other.val) return 0;
            return this.val>other.val?1:-1;
        }
    }

    // ---------- SUMMARY MAIN ----------
    @AuraEnabled(cacheable=true)
    public static Summary getSummary(String partNumber, Id accountId) {
        if (String.isBlank(partNumber)) throw new AuraHandledException('Part Number is required.');

        // ----- time windows -----
        Date today = Date.today();
        Date firstOfThisMonth = Date.newInstance(today.year(), today.month(), 1);
        Integer qStartMonth = (((today.month()-1)/3)*3)+1;
        Date firstOfQuarter  = Date.newInstance(today.year(), qStartMonth, 1);
        Date priorQ1Start = firstOfQuarter.addMonths(-3), priorQ1End = firstOfQuarter.addDays(-1);
        Date priorQ2Start = firstOfQuarter.addMonths(-6), priorQ2End = priorQ1Start.addDays(-1);
        Date priorQ3Start = firstOfQuarter.addMonths(-9), priorQ3End = priorQ2Start.addDays(-1);
        Date firstOfYear   = Date.newInstance(today.year(), 1, 1);
        Date lastMonthStart= firstOfThisMonth.addMonths(-1), lastMonthEnd = firstOfThisMonth.addDays(-1);
        Date lastYearStart = Date.newInstance(today.year()-1,1,1), lastYearEnd=Date.newInstance(today.year()-1,12,31);
        Date last2YearStart= Date.newInstance(today.year()-2,1,1), last2YearEnd=Date.newInstance(today.year()-2,12,31);
        Date horizonStart  = today.addYears(-5);

        // ----- detect fields on QLI -----
        Map<String, Schema.SObjectField> qli = QuoteLineItem.SObjectType.getDescribe().fields.getMap();

        String qliPartField = pick(qli, new List<String>{
            'varcpq__PartNumber__c','Part_Number__c','PartNumber__c','PartNo__c','PartNum__c','PartCode__c','Part_Text__c'
        });
        String qliExtField = pick(qli, new List<String>{
            'varcpq__EXT_Price__c','ExtPrice__c','ExtendedPrice__c','Extended_Price__c'
        });
        String qliSalesUnitField = pick(qli, new List<String>{
            'varcpq__SalesPrice__c','varcpq__SalePrice__c','varcpq__Sale_Price__c',
            'SalesPrice__c','NetPrice__c','Net_Price__c','CustomerPrice__c','Customer_Price__c'
        });
        // Unit Cost (this is what drives Avg Unit Price in UI)
        String qliCostField = pick(qli, new List<String>{
            'varcpq__Unit_Cost__c','varcpq__UnitCost__c',
            'UnitCost__c','Cost__c','EstimatedUnitCost__c','Unit_Cost__c'
        });
        // Stored Margin % (primary)
        String qliMarginPctField = pick(qli, new List<String>{
            'varcpq__Margin_Percentage__c','varcpq__MarginPercent__c','MarginPercent__c','Margin_Pct__c','Margin__c'
        });

        // Product2.StandardCost (final fallback for cost)
        Map<String, Schema.SObjectField> p2 = Product2.SObjectType.getDescribe().fields.getMap();
        Boolean productHasStdCost = p2.containsKey('StandardCost');

        // ----- WHERE: QLI.Part# or PBE.Product2.ProductCode -----
        List<String> ors = new List<String>();
        if (qliPartField != null) ors.add(qliPartField + ' = :partNumber');
        ors.add('PricebookEntry.Product2.ProductCode = :partNumber');
        String partWhere = '(' + String.join(ors, ' OR ') + ')';
        String acctFilter = (accountId == null) ? '' : ' AND Quote.AccountId = :accountId';

        // ----- SELECT (include Quote.CreatedDate!) -----
        List<String> selects = new List<String>{
            'Id','CreatedDate','Quantity','UnitPrice', // UnitPrice = COST in this org
            'QuoteId','Quote.CreatedDate','Quote.QuoteNumber','Quote.AccountId','Quote.Account.Name',
            'PricebookEntry.Pricebook2.Name',
            'PricebookEntry.Product2.ProductCode'
        };
        if (qliExtField != null)       selects.add(qliExtField);
        if (qliSalesUnitField != null) selects.add(qliSalesUnitField);
        if (qliCostField != null)      selects.add(qliCostField);
        if (qliMarginPctField != null) selects.add(qliMarginPctField);
        if (productHasStdCost)         selects.add('PricebookEntry.Product2.StandardCost');

        String soql =
            'SELECT ' + String.join(selects, ',') +
            ' FROM QuoteLineItem' +
            ' WHERE ' + partWhere +
            ' AND Quote.CreatedDate >= :horizonStart' + acctFilter +
            ' ORDER BY Quote.CreatedDate DESC, CreatedDate DESC' +
            ' LIMIT 5000';

// Normalize the key we search by
String key = (partNumber == null) ? null : partNumber.trim();

// Try tight: exact match + last 5 years
List<QuoteLineItem> lines = fetchLinesForPart(
    key, horizonStart, accountId, qliPartField, selects, /*useLooseMatching*/ false
);

// If nothing, try loose: LIKE match + no date fence
if (lines.isEmpty()) {
    lines = fetchLinesForPart(
        key, horizonStart, accountId, qliPartField, selects, /*useLooseMatching*/ true
    );
}

        // ----- init response -----
        Summary s = new Summary();
        s.currentMonth = new WindowKpi(); s.lastMonth = new WindowKpi();
        s.priorQ1 = new WindowKpi(); s.priorQ2 = new WindowKpi(); s.priorQ3 = new WindowKpi();
        s.ytd = new WindowKpi(); s.lastYear = new WindowKpi(); s.lastToLastYear = new WindowKpi();
        s.lifetime = new WindowKpi();

        List<TxnRow> txns = new List<TxnRow>();
        List<ValWeight> vw = new List<ValWeight>();
        Map<Id,AccountSummary> acctMap = new Map<Id,AccountSummary>();

        for (QuoteLineItem li : lines) {
            Date dte = li.Quote.CreatedDate.date();
            Decimal qty = (li.Quantity == null ? 0 : li.Quantity);

            // Sales (unit) price
            Decimal saleUnit = null;
            if (qliSalesUnitField != null) saleUnit = (Decimal) li.get(qliSalesUnitField);

            // Revenue (EXT)
            Decimal ext = (qliExtField != null) ? (Decimal) li.get(qliExtField) : null;

            // Derive if one is missing
            if (saleUnit == null && ext != null && qty > 0) saleUnit = ext / qty;
            if (ext == null && saleUnit != null) ext = saleUnit * qty;
            if (saleUnit == null) saleUnit = 0;
            if (ext == null) ext = 0;

            // Unit COST (what we now average for "Avg Unit Price")
            Decimal unitCost = null;
            if (qliCostField != null) unitCost = (Decimal) li.get(qliCostField);
            if (unitCost == null && UNITPRICE_IS_COST) unitCost = (li.UnitPrice == null ? 0 : li.UnitPrice);
            if (unitCost == null && productHasStdCost && li.getSObject('PricebookEntry') != null) {
                SObject pbe = li.getSObject('PricebookEntry');
                if (pbe != null) {
                    SObject p2rec = pbe.getSObject('Product2');
                    if (p2rec != null) unitCost = (Decimal) p2rec.get('StandardCost');
                }
            }

            // Margin %: prefer stored field, fallback if missing
            Decimal marginPct = null;
            if (qliMarginPctField != null) {
                Decimal pct = (Decimal) li.get(qliMarginPctField);
                if (pct != null) marginPct = (pct > 1) ? pct/100 : pct; // handle 13.2 vs 0.132
            }
            if (marginPct == null) {
                marginPct = (saleUnit > 0 && unitCost != null) ? (saleUnit - unitCost) / saleUnit : 0;
            }

            // build row
            TxnRow row = new TxnRow();
            row.dt = li.Quote.CreatedDate;
            row.quoteId = li.QuoteId;
            row.quoteNumber = li.Quote.QuoteNumber;
            row.accountId = li.Quote.AccountId;
            row.accountName = (li.Quote.Account == null ? null : li.Quote.Account.Name);
            row.qty = qty; row.unitPrice = saleUnit; row.extPrice = ext;
            row.unitCost = unitCost; row.marginPct = marginPct;
            row.pricebookName = (li.PricebookEntry==null||li.PricebookEntry.Pricebook2==null)?null:li.PricebookEntry.Pricebook2.Name;
            txns.add(row);

            // global windows (per-bucket lastDate)
            addInto(s.lifetime, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= firstOfThisMonth) addInto(s.currentMonth, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= lastMonthStart && dte <= lastMonthEnd) addInto(s.lastMonth, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= priorQ1Start && dte <= priorQ1End) addInto(s.priorQ1, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= priorQ2Start && dte <= priorQ2End) addInto(s.priorQ2, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= priorQ3Start && dte <= priorQ3End) addInto(s.priorQ3, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= firstOfYear) addInto(s.ytd, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= lastYearStart && dte <= lastYearEnd) addInto(s.lastYear, qty, ext, saleUnit, unitCost, marginPct, dte);
            if (dte >= last2YearStart && dte <= last2YearEnd) addInto(s.lastToLastYear, qty, ext, saleUnit, unitCost, marginPct, dte);

            if (qty > 0 && saleUnit != null) vw.add(new ValWeight(saleUnit, qty));

            // per-account
            if (row.accountId != null) {
                AccountSummary a = acctMap.get(row.accountId);
                if (a == null) {
                    a = new AccountSummary();
                    a.accountId = row.accountId; a.accountName = row.accountName;
                    a.currentMonth = new WindowKpi(); a.lastMonth = new WindowKpi();
                    a.priorQ1 = new WindowKpi(); a.priorQ2 = new WindowKpi(); a.priorQ3 = new WindowKpi();
                    a.ytd = new WindowKpi(); a.lastYear = new WindowKpi(); a.lastToLastYear = new WindowKpi();
                    a.lifetime = new WindowKpi();
                    acctMap.put(a.accountId, a);
                }
                if (a.latest == null) a.latest = row; // list is date desc
                addInto(a.lifetime, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= firstOfThisMonth) addInto(a.currentMonth, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= lastMonthStart && dte <= lastMonthEnd) addInto(a.lastMonth, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= priorQ1Start && dte <= priorQ1End) addInto(a.priorQ1, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= priorQ2Start && dte <= priorQ2End) addInto(a.priorQ2, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= priorQ3Start && dte <= priorQ3End) addInto(a.priorQ3, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= firstOfYear) addInto(a.ytd, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= lastYearStart && dte <= lastYearEnd) addInto(a.lastYear, qty, ext, saleUnit, unitCost, marginPct, dte);
                if (dte >= last2YearStart && dte <= last2YearEnd) addInto(a.lastToLastYear, qty, ext, saleUnit, unitCost, marginPct, dte);
            }
        }

        // finalize windows
        finalizeKpi(s.currentMonth); finalizeKpi(s.lastMonth);
        finalizeKpi(s.priorQ1); finalizeKpi(s.priorQ2); finalizeKpi(s.priorQ3);
        finalizeKpi(s.ytd); finalizeKpi(s.lastYear); finalizeKpi(s.lastToLastYear);
        finalizeKpi(s.lifetime);
        for (AccountSummary a : acctMap.values()) {
            finalizeKpi(a.currentMonth); finalizeKpi(a.lastMonth);
            finalizeKpi(a.priorQ1); finalizeKpi(a.priorQ2); finalizeKpi(a.priorQ3);
            finalizeKpi(a.ytd); finalizeKpi(a.lastYear); finalizeKpi(a.lastToLastYear);
            finalizeKpi(a.lifetime);
        }

        if (!txns.isEmpty()) s.latest = txns[0];

        if (!vw.isEmpty()) {
            vw.sort();
            List<Decimal> pct = weightedPercentiles(vw, new List<Decimal>{0.25, 0.50, 0.75});
            s.p25 = pct[0]; s.p50 = pct[1]; s.p75 = pct[2];
        }

        s.transactions = txns;
        s.accounts = new List<AccountSummary>(acctMap.values());
        return s;
    }

    // ---- helpers ----
    private static String pick(Map<String, Schema.SObjectField> fmap, List<String> candidates) {
        for (String c : candidates) if (fmap.containsKey(c)) return c;
        return null;
    }
    private static void addInto(WindowKpi k, Decimal qty, Decimal ext, Decimal unitSalePrice, Decimal unitCost, Decimal marginPct, Date dte) {
        Decimal q = (qty == null ? 0 : qty);
        Decimal e = (ext == null ? 0 : ext);
        Decimal c = (unitCost == null ? 0 : unitCost);
        k.units += q;
        k.revenue += e;
        k.extSum += e;
        k.costQtySum += (c * q);                // accumulate cost × qty
        k.marginExtSum += ((marginPct == null ? 0 : marginPct) * e);
        if (k.lastPrice == null && unitSalePrice != null) k.lastPrice = unitSalePrice;
        if (k.lastDate == null || (dte != null && dte > k.lastDate)) k.lastDate = dte;
    }
    private static void finalizeKpi(WindowKpi k) {
        // Avg Unit Price in UI = Avg Unit COST here
        if (k.units != 0) k.avgUnitPrice = k.costQtySum / k.units;
        else k.avgUnitPrice = 0;
        k.avgMarginPct = (k.extSum > 0) ? (k.marginExtSum / k.extSum) : 0;
    }
    private static List<Decimal> weightedPercentiles(List<ValWeight> arr, List<Decimal> ps) {
        Decimal totalW = 0; for (ValWeight v : arr) totalW += v.w;
        List<Decimal> out = new List<Decimal>();
        if (totalW == 0) { for (Integer i=0;i<ps.size();i++) out.add(0); return out; }
        for (Decimal p : ps) {
            Decimal target = totalW * p, cum = 0, result = arr[0].val;
            for (ValWeight v : arr) { cum += v.w; if (cum >= target) { result = v.val; break; } }
            out.add(result);
        }
        return out;
    }

    // ---------- QLI Typeahead search (source of truth) ----------
    public class PartPickOption {
        @AuraEnabled public String label;   // e.g., "ARMDUAL — Test Four (last used 2025-07-22)"
        @AuraEnabled public String value;   // the part number string to run
        public PartPickOption(String l, String v){ label = l; value = v; }
    }

    /**
     * Search unique Part Numbers from QuoteLineItem by term.
     * Matches QLI Part Number text, QLI Description, and Product2.ProductCode/Name.
     * Returns most-recently-used first, up to maxResults unique part numbers.
     */
   @AuraEnabled(cacheable=true)
public static List<PartPickOption> searchPartNumbers(String term, Integer maxResults) {
    List<PartPickOption> out = new List<PartPickOption>();

    Integer limitSize = (maxResults == null || maxResults < 5) ? 20 : maxResults;

    Map<String, Schema.SObjectField> qli = QuoteLineItem.SObjectType.getDescribe().fields.getMap();

    // Detect your QLI Part Number text field
    String partField = null;
    for (String c : new List<String>{
        'varcpq__PartNumber__c','Part_Number__c','PartNumber__c','PartNo__c','PartNum__c','PartCode__c','Part_Text__c'
    }) { if (qli.containsKey(c)) { partField = c; break; } }

    // Optional description for richer labels
    String descField = qli.containsKey('Description') ? 'Description' : null;

    // If we still can't identify a part field, bail (nothing meaningful to search)
    if (partField == null) return out;

    List<QuoteLineItem> rows;

    if (String.isBlank(term)) {
        // Blank term: show most recently used parts (QLI only)
        String soqlRecent =
            'SELECT ' + partField +
            (descField != null ? ',' + descField : '') +
            ', Quote.CreatedDate FROM QuoteLineItem ' +
            'WHERE ' + partField + ' != NULL ' +
            'ORDER BY Quote.CreatedDate DESC NULLS LAST ' +
            'LIMIT 400';
        rows = Database.query(soqlRecent);
    } else {
        String likeTerm = '%' + term + '%';
        List<String> whereBits = new List<String>();
        whereBits.add(partField + ' LIKE :likeTerm');
        if (descField != null) whereBits.add(descField + ' LIKE :likeTerm');
        String whereClause = '(' + String.join(whereBits, ' OR ') + ')';

        String soqlSearch =
            'SELECT ' + partField +
            (descField != null ? ',' + descField : '') +
            ', Quote.CreatedDate FROM QuoteLineItem ' +
            'WHERE ' + whereClause +
            'ORDER BY Quote.CreatedDate DESC ' +
            'LIMIT 400';
        rows = Database.query(soqlSearch);
    }

    // Deduplicate by the QLI part number, most-recent-first
    Set<String> seen = new Set<String>();
    for (QuoteLineItem li : rows) {
        String part = (String) li.get(partField);
        if (String.isBlank(part) || seen.contains(part)) continue;

        String descText = (descField != null) ? (String) li.get(descField) : null;
        Date lastUsed = (li.Quote != null && li.Quote.CreatedDate != null) ? li.Quote.CreatedDate.date() : null;

        String label = part + (String.isBlank(descText) ? '' : ' — ' + descText);
        if (lastUsed != null) label += '  (last used ' + String.valueOf(lastUsed) + ')';

        out.add(new PartPickOption(label, part));
        seen.add(part);
        if (out.size() >= limitSize) break;
    }
    return out;
}

// Helper: run the QLI query with either exact (tight) or LIKE (loose) matching,
// and optionally with the 5-year horizon (tight) or no horizon (loose).
private static List<QuoteLineItem> fetchLinesForPart(
    String key,                // trimmed part number
    Date horizonStart,         // 5-year fence
    Id accountId,              // optional filter
    String qliPartField,       // detected QLI part field
    List<String> selects,      // SELECT field list already built
    Boolean useLooseMatching   // false = exact + 5yrs; true = LIKE + no horizon
){
    if (String.isBlank(key)) return new List<QuoteLineItem>();
    String likeKey = '%' + key + '%';

    List<String> ors = new List<String>();
    if (qliPartField != null) {
        ors.add( useLooseMatching
                 ? (qliPartField + ' LIKE :likeKey')
                 : (qliPartField + ' = :key') );
    }
    // Also allow ProductCode as a secondary key (some rows might be tied to Products)
    ors.add( useLooseMatching
             ? 'PricebookEntry.Product2.ProductCode LIKE :likeKey'
             : 'PricebookEntry.Product2.ProductCode = :key' );

    String partWhere = '(' + String.join(ors, ' OR ') + ')';
    String acctFilter = (accountId == null) ? '' : ' AND Quote.AccountId = :accountId';
    String horizon    = useLooseMatching ? '' : ' AND Quote.CreatedDate >= :horizonStart';

    String soql =
        'SELECT ' + String.join(selects, ',') +
        ' FROM QuoteLineItem' +
        ' WHERE ' + partWhere + horizon + acctFilter +
        ' ORDER BY Quote.CreatedDate DESC, CreatedDate DESC' +
        ' LIMIT 5000';

    // Both variables are in scope; the SOQL will only use the ones referenced.
    return Database.query(soql);
}


}