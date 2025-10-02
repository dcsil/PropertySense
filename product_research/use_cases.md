# Use Cases

## Jobs To Be Done (JTBD)

1. **As a Canadian homeowner preparing to sell**, I want to obtain an accurate property valuation that incorporates visual inspections of my home's condition, so that I can set realistic pricing expectations and identify potential flaws that could affect market value.  
2. **As a Canadian looking to buy a new house**, I want to use AI-assisted photo analysis to generate preliminary risk reports, and help me evaluate the conditions of a new house, so I can attend more house-showings efficiently.  
3. **As a real estate broker**, I want to quickly analyze client-submitted photos for property risks and flaws, so that I can provide informed advice on repairs and valuations to facilitate faster sales.

---

## Critical User Journeys (CUJs)

### CUJ 1: Property Valuation with Basic Data Input  
- **Scenario**: The user enters property details like address and specs to get an initial valuation estimate.  
- **Journey**:  
  1. User logs into the app via web or iOS.  
  2. User inputs address, beds/baths/sqft, age, and other public data fields.  
  3. System pulls regional data from APIs and computes a baseline valuation range.  
  4. User reviews the estimate with explanations of factors considered.
  5. Option to proceed to photo upload for enhanced accuracy.
- **UI/UX demonstration**:
![](./use_cases_asset/CUJ1_1.png)
![](./use_cases_asset/CUJ1_2.png)

---

### CUJ 2: Photo Upload and Flaw Detection  
- **Scenario**: The user uploads photos of key property areas for AI-based inspection.  
- **Journey**:  
  1. From the valuation dashboard, user selects "Add Photos" and follows prompts for angles (e.g., roof, interior).  
  2. App processes images using CV models to detect flaws like cracks or wear.  
  3. System generates a condition grade and risk report, highlighting issues.  
  4. User views annotated photos with flaw markers and severity scores.  
  5. Updated valuation incorporates flaw insights, optionally with repair cost estimates.  
- **UI/UX demonstration**:
![](./use_cases_asset/CUJ2_1.png)
![](./use_cases_asset/CUJ2_2.png)

---

### CUJ 3: Comprehensive Report Generation and Sharing  
- **Scenario**: The user compiles valuation and inspection data into a report.  
- **Journey**:  
  1. After data input and photo analysis, user selects "Generate Report"
  2. System aggregates the generated valuation range, flaw detections, regional comparisons, etc. into a single report.
  3. Report includes visualizations like charts and annotated images.  
  4. User customizes (e.g., add notes) and exports as PDF or shares via link.  
  5. Option to invite collaborators (e.g., broker) for feedback.  
- **UI/UX demonstration**:
![](./use_cases_asset/CUJ3_1.png)

---

### CUJ 4: Broker Review and Adjustment  
- **Scenario**: A broker reviews a client-generated report and makes professional adjustments.  
- **Journey**:  
  1. Broker receives shared report link and logs in.  
  2. Views AI-generated valuation and flaw detections.  
  3. Manually overrides estimates or adds notes based on expertise.  
  4. System recalculates updated valuation.  
  5. Broker shares revised report back with client.  
- **UI/UX demonstration**:
![](./use_cases_asset/CUJ4_1.png)

---

### CUJ 5: Inspector Flaw Prioritization  
- **Scenario**: An inspector uses the app to prioritize flaws for on-site verification.  
- **Journey**:  
  1. Inspector uploads or accesses client photos.  
  2. AI analyzes for high-risk flaws (e.g., structural issues).  
  3. System ranks flaws by severity and suggests inspection order.  
  4. Inspector marks items as verified or adds field notes.  
  5. Updated report syncs with valuation adjustments.  
- **UI/UX demonstration**:
![](./use_cases_asset/CUJ5_1.png)