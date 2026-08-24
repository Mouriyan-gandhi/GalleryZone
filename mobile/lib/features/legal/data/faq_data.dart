// Generated from `frontend-web/features/faq/faq-data.ts`.
//
// The web page renders only three audience tabs and silently drops its 22
// aggregator entries; this app has an aggregator portal, so all four are
// listed here.

enum FaqAudience { general, artists, aggregators, buyers }

const faqAudienceLabel = <FaqAudience, String>{
  FaqAudience.general: 'General',
  FaqAudience.artists: 'Artists',
  FaqAudience.aggregators: 'Aggregators',
  FaqAudience.buyers: 'Buyers',
};

class FaqItem {
  const FaqItem({required this.audience, required this.question, required this.answer});

  final FaqAudience audience;
  final String question;
  final String answer;
}

const faqItems = <FaqItem>[
  FaqItem(
    audience: FaqAudience.general,
    question: 'What is GalleryZone?',
    answer: 'GalleryZone is a verified marketplace for original artwork. It connects independent artists directly with collectors through an online marketplace, and with curated gallery partners, called aggregators, who can display and sell work in person.',
  ),
  FaqItem(
    audience: FaqAudience.general,
    question: 'How is pricing kept private?',
    answer: 'Every artist sets a private listed price that is never shown to buyers or the public. The marketplace price shown everywhere else already includes GalleryZone\'s markup, so an artist\'s confidential price and market value stay protected across every channel.',
  ),
  FaqItem(
    audience: FaqAudience.general,
    question: 'What does the Verified badge mean?',
    answer: 'Verified artists have linked an official social media handle, kept an active GalleryZone plan for three months, and completed at least one confirmed sale. Clearing all three unlocks the Gold ✦ Verified badge, shown on their profile and every listing.',
  ),
  FaqItem(
    audience: FaqAudience.general,
    question: 'Is there a fee to list artwork?',
    answer: 'No. Listing is free, with a 0% confirmation fee when artwork is accepted. GalleryZone earns its margin from the markup on the customer-facing price, never from a submission or listing fee.',
  ),
  FaqItem(
    audience: FaqAudience.general,
    question: 'How do I know an artwork is genuine?',
    answer: 'Every artwork is linked to a Certificate of Authenticity and a signed origin declaration, plus a physical QR tag that resolves to its digital passport, showing ownership history for the artwork\'s life cycle.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'What is GalleryZone?',
    answer: 'GalleryZone is a verified art marketplace designed to connect independent artists, aggregators/distributors, and buyers through a structured platform with defined artwork, ownership, and financial procedures.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'How can I list my artwork?',
    answer: 'Create your artist profile, accept the applicable artist guidelines, and submit the required artwork information, including the title, medium, dimensions, year, description, authenticity information, condition details, photographs, and your private listed price.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Who can see my artist price?',
    answer: 'Your listed artist price is confidential. It is not displayed to customers or publicly on the marketplace. Aggregators may see it for business decision-making.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'How is the customer selling price calculated?',
    answer: 'The customer selling price is calculated at 130% of the artist\'s listed price, representing a 30% markup. For example, an artist price of ₹10,000 results in a customer price of ₹13,000 + GST.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'How much will I receive when my artwork sells?',
    answer: 'The artist receives the full listed price. Customer-paid delivery charges are not deducted from the artist settlement if the sale is made through the marketplace. However, if the sale is made through an aggregator channel, delivery charges, convenience charges, and any other applicable charges will be deducted from the artist price.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Is there an acceptance or confirmation fee?',
    answer: 'No. There is no fee for listing an artwork. We are currently working on a subscription-based model.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Is transit insurance mandatory?',
    answer: 'No. Transit insurance is optional for marketplace listings. For uninsured artwork, the risk remains with the artist. For sales through the aggregator channel, insurance is mandatory and is purchased at the artist\'s cost. The insurance cost is approximately 1% of the artwork value.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'What happens if my artwork is not sold within 30 days?',
    answer: 'The artwork may be moved to the next available aggregator. The customer selling price is reduced by 10%; the artist\'s original listed price is not reduced.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Can I list the same artwork elsewhere while it is active?',
    answer: 'No. Once an artwork is accepted and active on the platform, it may not be listed or sold through another channel during the active period. If the artwork is promoted or sold through Instagram, you must provide the GalleryZone website link for the artwork.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'How does artist verification work?',
    answer: 'Full verification requires three criteria: at least one linked social media account, an active paid subscription, and at least one confirmed sale through the platform.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'How can I demonstrate authenticity?',
    answer: 'Artists can provide authenticity statements, Certificate of Authenticity (COA) details, and social-proof links showing studio processes, materials, work-in-progress, or signature details. Social-proof content must not display or mention the price or monetary valuation of the artwork.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'When is my settlement paid?',
    answer: 'Settlement is processed within 7 days after the aggregator records a confirmed sale through the platform.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'What rights do I retain after selling my artwork?',
    answer: 'Under the current model, the buyer receives the commercial and ownership rights upon confirmed sale and delivery, while the artist retains moral rights as the creator.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Do I need to ship my artwork immediately after listing?',
    answer: 'The artwork is first submitted and reviewed. Once it is accepted and the required procedures and item arrangements are completed, it may be made available for aggregator collection and sale.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'How many photographs can I upload?',
    answer: 'Up to 8 photographs can be provided, including cover, detail, signature, and scale-reference photographs.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'What information is required for an artwork listing?',
    answer: 'The following information is required: title, medium, dimensions, year of creation, description, authenticity statement, warranty/material information, photographs, private artist price, and logistics information.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Can I mention the artwork price in my description?',
    answer: 'No. The artwork description must not contain the price, valuation, or any other monetary figures.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Can I change my artist price after listing?',
    answer: 'The current procedures state that the artist price remains fixed once the artwork is listed. Any related edits are valid only for 7 days.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Can I withdraw an artwork after it has been accepted?',
    answer: 'The current document establishes exclusivity once an artwork is accepted and becomes active. Any withdrawal procedure should therefore follow the applicable platform terms and administrative process. You may mark the artwork as sold; however, a fee equivalent to 1% of the artwork value must be paid at the time of your next listing as a repercussion.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'What happens if my artwork is damaged during transit?',
    answer: 'If transit insurance has been selected, the applicable insurance process will apply. Without insurance, the procedures state that GalleryZone, its staff, and aggregators bear no liability for transit damage, loss, or theft.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'Can I use social media to promote my artwork?',
    answer: 'Yes. Social media proof can be linked to the artwork to demonstrate the creation process and strengthen authenticity. However, the linked content must not mention or display the price or valuation of the artwork. Any sale through social media should be converted through the GalleryZone platform by providing the website link to the respective artwork.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'What happens when I make my first sale?',
    answer: 'A confirmed sale contributes to your artist verification progress and is one of the three requirements for achieving full verified status.',
  ),
  FaqItem(
    audience: FaqAudience.artists,
    question: 'What is the Certificate of Authenticity?',
    answer: 'Where provided by the artist, the Certificate of Authenticity (COA) forms part of the artwork\'s authenticity documentation and is made available to the customer through the platform.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What is an aggregator?',
    answer: 'An aggregator is a display and sales partner. Aggregators take physical possession of selected artworks, display them in their gallery or approved space, and work to find buyers. They do not become the legal owners of the artworks.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'How do I add an artwork to my collection?',
    answer: 'Browse the available artworks, review the pricing breakdown, pay the 5% advance plus delivery charges based on the customer selling price, and confirm the collection. The artwork is then dispatched to your gallery or approved display location.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What is the aggregator advance?',
    answer: 'The aggregator pays 5% of the customer selling price as an advance when taking possession of the artwork. The amount will be settled when the artwork is sold.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Is the 5% advance refundable?',
    answer: 'It is refundable only if the platform cancels the arrangement before dispatch. Once the artwork has been dispatched to the aggregator, the advance is non-refundable and will only be settled in the wallet after completion of the 30-day period.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'How long do I have to sell an artwork?',
    answer: 'An artwork is normally held for a maximum of 30 days in an aggregator\'s collection.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What happens after 30 days?',
    answer: 'The customer selling price is reduced by 10%, and the artwork may be moved to the next available aggregator. The reduction is applied to the markup price, not the artist price.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'How does the aggregator incentive work?',
    answer: 'The aggregator receives an incentive equal to 20% of the 30% markup/appreciation. For an artist price of ₹10,000 and a customer price of ₹13,000, the ₹3,000 appreciation produces a ₹600 aggregator incentive.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Can I negotiate or discount the customer price?',
    answer: 'The customer selling price is set by the platform. An aggregator cannot independently discount it. Any price below the established customer price requires prior approval from the platform.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Can I disclose the artist\'s private price?',
    answer: 'No. The artist price is confidential and must not be disclosed to customers or third parties.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Who owns an artwork while it is in my gallery?',
    answer: 'The platform retains legal ownership while the artwork is in the aggregator\'s possession. The aggregator acts only as a display and sales partner.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What should I do when I find a buyer?',
    answer: 'Record the sale immediately through the Aggregator Portal, including the final sold price and the required buyer information. The confirmed sale triggers the settlement, rights-transfer, and incentive processes.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Who pays delivery charges?',
    answer: 'The customer pays the delivery charges separately. The platform coordinates delivery through third-party logistics providers.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What are my responsibilities while holding the artwork?',
    answer: 'The aggregator must protect and properly handle the artwork, prepare it for pickup after the sale, and follow the platform\'s logistics process while the artwork is in their possession.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Can I sell or transfer the artwork outside the platform?',
    answer: 'No. The aggregator may not sell, pledge, or transfer the artwork outside the platform\'s approved process.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Can I choose which artworks I want to display?',
    answer: 'The Aggregator Portal allows you to browse available artworks and select artworks for your collection, subject to the platform\'s procedures.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What happens if an uninsured artwork is damaged while in my possession?',
    answer: 'The aggregator bears responsibility for damage to uninsured artwork while it is in their possession. If the loss or damage occurs and insurance is applicable, the relevant insurance process will apply.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Can I hand the artwork directly to the customer?',
    answer: 'Yes. You can hand the artwork directly to the customer in the respective art box by recording the sale and selecting the "Self-Picked" option at the time of recording the sale.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Who arranges delivery after I make a sale?',
    answer: 'The platform manages delivery bookings through third-party logistics providers. The aggregator must ensure that the artwork is properly packaged and ready for pickup.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Why must I record the sale immediately?',
    answer: 'A confirmed sale triggers the artist settlement, aggregator incentive, rights-transfer process, and platform margin booking.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What information must I collect from a buyer?',
    answer: 'The sale record requires the following information: final sold price, buyer\'s full name, email address, phone number, complete delivery address, and any relevant notes.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'What information can I see before selecting an artwork?',
    answer: 'The Aggregator Portal provides the artist price, customer selling price, advance requirement, and incentive information so that you can evaluate the artwork commercially.',
  ),
  FaqItem(
    audience: FaqAudience.aggregators,
    question: 'Can I display the artwork anywhere?',
    answer: 'The artwork\'s display location is recorded in the inventory system as the aggregator\'s gallery or approved display space.',
  ),
  FaqItem(
    audience: FaqAudience.buyers,
    question: 'What rights do I get when I buy a piece?',
    answer: 'Once your delivery is confirmed, you receive the right to display, reproduce, license, and commercially use or resell the physical artwork.',
  ),
  FaqItem(
    audience: FaqAudience.buyers,
    question: 'Does the artist keep any rights after I buy their work?',
    answer: 'Yes. The artist permanently retains moral rights as the original creator, recorded against the piece regardless of who owns it.',
  ),
  FaqItem(
    audience: FaqAudience.buyers,
    question: 'Can I resell art I\'ve bought?',
    answer: 'Registered customers can resell authenticated artwork through GalleryZone, which supports a secondary market with resale royalties rather than a private, unverifiable sale.',
  ),
  FaqItem(
    audience: FaqAudience.buyers,
    question: 'How do I know a piece is authentic before I buy it?',
    answer: 'Every listing links to a Certificate of Authenticity, a signed origin declaration, and the artwork\'s QR passport page, so you can verify its history independently of the listing itself.',
  ),
  FaqItem(
    audience: FaqAudience.buyers,
    question: 'Is my order insured in transit?',
    answer: 'Artwork valued above ₹20,000 is strongly recommended for transit insurance through GalleryZone\'s partner HDFC ERGO. Look for the insured badge on a listing; delivery charges are billed separately from the artwork price.',
  ),
];
