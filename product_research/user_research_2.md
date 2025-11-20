# User Research Report 2: Home Repair Platform User Testing

## Research Overview

- **Research Round:** Round 2 - UI/UX & Accessibility testing
- **Date:** October 18, 2025
- **Methodology:** In-Person User Test
- **Sample Size:** 1
- **User Persona:** UofT student studying Industrial Engineering, age 21, new PropertySense user, renter, moderate-high technical proficiency.

## Executive Summary
User was given a Testflight build of PropertySense running on a Iphone 15 Plus and was instructed to create an account, login and create a listing for a fake repair scenario.

The user was able to easily register using the "Sign up with Google" option. They first attempted to use the "Sign Up with Apple" option but it was not implemented yet. They made there way through the registration screen with relatively low effort, with certain UI comments (see #1 & #2 below). Once they made their way to the homeowner homepage, they found their way to the listing creation flow. They found the relevant repair category, then proceeded to upload an image, then filled out information regarding the listing price and description. 

They were then re-directed to the homepage, where they were confused as the listing was not visible. They then pulled the page down to trigger a refresh, which then showed the listing. They knew this due to their mobile app intuition, however, this isn't something we expect the average user to be aware of.

They inspected the listing by clicking on it, at which they noticed the "Publish" button and published the listing for contractors to see. 

## User Feedback
The user liked the sign up flow and the google Oauth integration as it avoided email verification. They mentioned that the UI bug during registration was confused and it led them to accidentally enter the contractor flow rather than the homeowner flow. They were not aware that the address selection field would show them a selection menu rather than just taking the text address. They liked this idea but led to some split-second confusion. Regarding the listing creation UX flow, they suggested that it would be nice to have a preview listing option before completing the full listing creation flow. They later understood that "creating" a listing doesn't automatically publish the listing for contractors. They found this to be counter-intuitive. They also pointed out UI bugs in the listing detail view, such as the author ID showing, rather than the author name. They found that showing this information was irrelevant, and would rather see data related to the contractors that viewed this listing, or messages from them.

## Key Findings & Recommendation

### 1. Registration: UI bug for User Type selection in Dark Mode
Currently, when the app switched to dark mode, the selection that IS NOT selected is not highlighted for the User Type Selection page in the registration field.


### 2. Registration: UI does not make it clear for users that the address field is a search bar.
Currently, the registration flow makes the "address" section appears as a text area for address input, however, it is actually a search bar which queries the closest address match.

### 3. Listing Creation: Homepage does not automatically refresh after listing creation
When users complete the listing creation flow and return to the homepage, their newly created listing does not appear immediately. Users must manually pull down to refresh the page. This creates confusion as users expect to see their listing right away and may think the creation failed. The app should automatically refresh the homepage data when returning from the listing creation flow to provide immediate visual confirmation of success.

### 4. Listing Creation: "Create" vs "Publish" distinction is counter-intuitive
Users expect that completing the listing creation flow will make their listing visible to contractors. However, listings are created in an unpublished state and require an additional "Publish" action from the listing detail view. This two-step process is not clearly communicated during creation, leading to confusion about why contractors aren't responding. Consider either: (a) auto-publishing listings upon creation with an option to save as draft, (b) adding a preview/publish step at the end of the creation flow, or (c) clearly indicating draft status during the creation process.

### 5. Listing Detail View: Technical data shown instead of actionable user information
The listing detail view displays technical backend information (author ID) rather than meaningful user-facing data. Users found this information irrelevant and expressed interest in seeing engagement metrics such as number of contractor views, received messages, or quote requests. The detail view should be redesigned to surface actionable information that helps users understand their listing's performance and manage contractor interactions.