# Use Cases

## Jobs To Be Done (JTBD)

1. **As a homeowner noticing a problem in my house**, I want to take photos of the issue and get an AI-generated diagnosis with a repair cost estimate, so I can understand the problem before contacting a professional.  
2. **As a homeowner needing quick repair service**, I want to receive offers from verified contractors nearby who can fix the issue for the estimated price, so I can book a repair easily and confidently.  
3. **As a licensed contractor or repair professional**, I want to view available nearby repair requests with AI-generated summaries and cost ranges, so I can choose jobs that fit my skills and schedule.

---

## Critical User Journeys (CUJs)

### CUJ 1: AI-Powered Issue Detection and Cost Estimation  
- **Scenario**: The homeowner captures and uploads photos of a home issue to receive an instant AI analysis.
- **Journey**:  
  1. User logs into the app on iOS.  
  2. User selects “New Repair Estimate” and uploads or captures photos of the issue (e.g., leaky pipe, cracked wall).  
  3. AI model analyzes the image to identify issue type and severity.  
  4. The system provides an estimated repair cost range, description of the detected issue, and possible causes.
  5. User can save or proceed to “Find a Contractor.”
- **UI/UX demonstration**:
<!--![](./cuj_input.jpg)-->

---

### CUJ 2: Contractor Matching and Job Posting  
- **Scenario**: The homeowner wants to connect with verified contractors to fix the identified issue.  
- **Journey**:  
  1. From the AI results page, user selects “Find a Contractor.”  
  2. System automatically creates a repair job listing with photos, issue summary, and estimated budget.  
  3. Verified contractors nearby receive the job request on their app, along with the AI’s estimate and image set.  
  4. Contractors review the photos, verify the issue, and submit their own offers, either confirming or adjusting the suggested price.
  5. Homeowner receives multiple offers with contractor profiles, ratings, and proposed prices.
  6. Homeowner compares offers and confirms a booking directly through the app.  
- **UI/UX demonstration**:
<!--![](./cuj_photo.jpg)-->
<!--![](./cuj_assess.jpg)-->

---

### CUJ 3: Contractor Workflow and Job Completion
- **Scenario**: A verified contractor accepts a repair job, completes the work, and both parties confirm the completion through the app.
- **Journey**:
   1. From the map view, the contractor browses nearby available repair listings created by homeowners.
   2. Contractor opens a listing, reviews the AI-generated issue summary and estimated cost, and decides to accept the job or submit a customized offer if their estimate differs.
   3. Once the homeowner confirms the booking, the contractor completes the assigned repair job.
   4. The contractor opens the job and marks it as “Completed by Me” and the system sends a notification to the homeowner to review the finished job.
   5. The homeowner reviews the work and sets the listing as “Completed,” triggering automatic payment processing.
   6. Both parties receive a receipt, and the option to rate each other.
- **UI/UX demonstration**:
<!--![](./cuj_dashboard.jpg)-->
<!--![](./cuj_update.jpg)-->

---
<!--
### CUJ 4: Comprehensive Report Generation and Sharing  
- **Scenario**: The user compiles valuation and inspection data into a report.  
- **Journey**:  
  1. After data input and photo analysis, user selects "Generate Report"
  2. System aggregates the generated valuation range, flaw detections, regional comparisons, etc. into a single report.
  3. Report includes visualizations like charts and annotated images. 
  4. User exports the generated report as PDF or private link.
- **UI/UX demonstration**:
![](./cuj_assess.jpg)
-->
---



## Functional Requirements

1. **Property Valuation & Data Integration**
   - Users can input basic property information (address, square footage, beds/baths, age, etc.).
   - The system retrieves regional market data via third-party APIs (e.g., MLS, census, municipal data).
   - The system generates an initial valuation range based on public data and comparable listings.
   - Explanations of factors influencing the valuation (e.g., square footage, location, age) are provided.
     
2. **Photo Upload & AI-Powered Flaw Detection**
   - Users can upload or capture photos on the mobile app.
   - The system provides prompts for required angles/areas (e.g., roof, kitchen, basement, exterior).
   - AI models analyze uploaded photos to detect flaws (e.g., cracks, roof wear, water damage).
   - Detected flaws are annotated directly on images with markers and severity scores.
   - Updated valuation incorporates flaw detection results, with optional repair cost estimates.

3. **Report Generation**
   - Users can generate a comprehensive property report combining valuation, flaw detection, and regional comparisons.
   - Reports include visualizations such as annotated images, charts, and condition summaries.
   - Users can export reports as PDFs for offline use.
   - Users can generate a secure, private link to share reports externally.

4. **Iterative Valuation Updates**
   - Users can open previously saved property sessions from a dashboard.
   - Users can replace or add new photos for specific property areas.
   - The system re-processes the updated photo set to detect changes in flaws or conditions.
   - A revised condition grade and updated valuation range are displayed.
   - The system highlights differences between the new and previous valuations (e.g., new flaws, improvements).
     
5. **Deployment and User Authentication**
   - iOS mobile app available through the App Store.
   - Users can register for an account and log in with email and password.
   - Authentication system ensures secure access to saved property sessions.

---

## Non-Functional Requirements

1. **Property Valuation & Data Integration**
   - Valuation calculations complete in ≤3 seconds for standard inputs.
   - Forms and valuation results must render correctly on iOS mobile screens.
   - System must handle API failures gracefully, displaying fallback messages without crashing.
     
2. **Photo Upload & AI-Powered Flaw Detection**
   - Photo upload must complete in ≤5 seconds per image on standard Wi-Fi.
   - AI analysis results returned in ≤10 seconds per batch of 5–10 images.
   - Annotated images must display consistently across devices and screen sizes.

3. **Report Generation**
   - Report generation (PDF or private link) must complete in ≤5 seconds.
   - Exported PDFs should be <10MB, optimized for sharing and mobile viewing.
   - Visualizations (charts, annotated images) must maintain consistent design system styling.
     
4. **Iterative Valuation Updates**
   - Dashboard and saved sessions must load in ≤2 seconds.
   - Updates with new photos must process and return revised valuation in ≤8 seconds.
   - Differences between old and new valuations must be highlighted clearly (ex. colour-coded).
   - System must handle multiple concurrent session updates without conflicts or errors.
     
5. **Deployment and User Authentication**
   - Authentication requests must complete in ≤2 seconds.
   - Auto-logout after 30 minutes of inactivity.
   - iOS mobile app must be fully compatible with the latest iOS version and responsive to various screen sizes.
   - System must support secure session persistence across app restarts and network changes.
  
---
