import 'dart:math';

/// WhatsApp-style Conversational Knowledge Base for ecoRoute Bot
/// Contains 400+ natural, human, local Arua City responses without robotic AI preambles.
class EcoRouteBotConversations {
  static final _random = Random();

  // =========================================================================
  // 1. GREETINGS & LOCAL UGANDAN SLANG (65 entries)
  // =========================================================================
  static final List<String> greetings = [
    // English casual
"Hey there! Hope your day in Arua is starting off great. Need a quick sack pickup?",
"Hello! Great to hear from you How can I help you today?",
"Hey! ecoRoute Bot here. What's happening around your compound today?",
"Hi hi! Always happy to chat. Got waste to clear or just saying hi?",
"Good morning! Wishing you a productive and clean day ahead. How can I assist?",
"Morning! Hope you slept well. Don't forget to tie up any full sacks before the morning truck passes!",
"Good afternoon! Hope the day is treating you well. Need any collection today?",
"Afternoon! Sun is up in Arua today Let me know if you need any rubbish cleared before evening.",
"Good evening! Hope you had a smooth day. Putting out any trash tonight?",
    "Evening! Relaxing after work? If you've got full bins, we can pick them up tomorrow morning.",
"Hey friend! What's good today? ecoRoute Bot is online and ready for you",
"Hello hello! How is everything on your side?",
    "Hi! Always a pleasure. How are things at home or at the shop today?",
"Yoo! What's popping? Ready to keep Arua clean together?",
    "Greetings! Hope your week is moving smoothly. How can I help you today?",
    "Hey! Quick check-in from ecoRoute Bot. Everything clean and organized?",
"Hello! Hope the hustle is going well today. Need a tricycle sent your way?",
    "Good day! How is the weather over there? Let me know whenever you need a pickup.",
    "Hey there! Just here making sure your waste collection is hassle-free. What's on your mind?",
"Hi! Welcome back to ecoRoute chat How are you feeling today?",

    // Lugbara (Local Arua language)
"Muke! Kopi ngoni? Hope you and the family are doing well in Arua today!",
"Muke muke! Ngoni amve? Ready to help you with your compound clean-up.",
"Kopi! How is Arua today? ecoRoute Bot is here at your service",
    "Muke! Inia ngoni? Hope the morning is peaceful on your side.",
"Kopi ngoni! If your trash sacks are full, just say the word and we'll dispatch a rider",
    "Muke amve! Awadifo for checking in. How is life today?",
    "Kopi! Everything fine around Ediofe and River Oli today? Let me know if you need collection.",
"Muke! Hope business is booming today. Got commercial waste to clear out?",
    "Kopi friend! We are moving around Arua town today. Need us to stop by?",
    "Muke! Stay blessed today. How can ecoRoute assist you right now?",

    // Swahili
"Habari yako! Natumai siku yako inaenda vizuri sana Arua. Nikusaidie aje leo?",
"Sasa! Mambo vipi? ecoRoute Bot yuko tayari kukusaidia na taka zako leo",
"Habari za asubuhi! Natumai umeamka salama. Kuna magunia ya taka ya kuchukua?",
"Habari za mchana! Joto kidogo Arua leo Je, unahitaji gari la taka leo?",
"Habari za jioni! Pumzika salama. Kama una taka, tunaweza kuchukua asubuhi.",
"Sasa rafiki! Niko hapa WhatsApp-style kukusaidia haraka bila stress",
    "Mambo! Kila kitu kiko shwari? Tuko tayari kuokota taka zako wakati wowote.",
    "Habari! Safi sana kuongea na wewe. Nikusaidie na nini leo?",
    "Sasa ndugu! Gari zetu ziko barabarani sasa hivi. Ungependa tukupitie?",
    "Habari yako bwana! Usiwe na wasiwasi, ecoRoute inahakikisha mji wetu ni safi daima.",

    // Luganda / Ugandan Slang
"Oli otya! Gyebaleko leero. Hope your day is going smoothly!",
"Ki kati! Everything cool? Let me know if you have full sacks at the gate",
"Oli bulungi? Bambi let us keep your compound sparkling clean today",
    "Banange, welcome! ecoRoute Bot is right here. How can I sort you out?",
"Agandi! Hope Western and West Nile breeze is feeling good today",
    "Wasuze otya nno! Good morning! Hope you slept like a baby.",
"Osiibye otya! Good afternoon! Don't let rubbish pile up under this heat",
    "Ki ekiganye? No stress, ecoRoute rider can reach your compound in no time.",
    "Oli otya ssebo/nnyabo! We are ready to collect your sacks at 2,500 UGX each.",
    "Webale kwogera nange! Thanks for texting me! What's on your agenda today?",

    // Friendly West Nile & City vibes
"Hello Arua champion! Keeping our city clean starts at your gate.",
"Top of the morning to you! The tricycles are already humming around town",
    "Hey! Hope you didn't get caught in the dust or rain today. How can I help?",
"Salute! ecoRoute Bot on duty 24/7. Shoot your question!",
    "A very warm welcome to you! Everything running on time today.",
"Hey! Just another beautiful sunny day in Arua City How are you?",
"Muke muke! Sending good vibes to your household or shop today",
    "Hello! Need a hand with sorting or booking? I'm your guy.",
    "Hey! Quick response guarantee right here. What's up?",
    "Good day! Your compound cleanliness is our top priority. What do you need?",
    "Hi there! Glad you reached out. Let's get things moving!",
    "Hello neighbor! ecoRoute Bot is here to make life easier.",
    "Hey! Skip the wait, tell me what you need and we will sort it out ASAP.",
"Yo! Hope your tea was hot and sweet this morning How can I assist?",
"Hey! ecoRoute Bot here, always online like WhatsApp What's good?"
  ];

  // =========================================================================
  // 2. SMALL TALK, CASUAL LIFE CHAT & DAILY CHECK-INS (55 entries)
  // =========================================================================
  static final List<String> smallTalk = [
"I'm doing super well, thanks for asking! Just keeping an eye on our collection routes in Arua.",
"All good here! Tricycles are out doing their morning rounds How is your day going?",
"Feeling great! It's always a pleasure to connect with people who care about keeping Arua clean",
    "I'm doing wonderful! Sun is shining, routes are clear, and waste is getting collected on time.",
    "Haha I can't complain at all! Just here on standby to answer your questions or send a rider.",
    "Doing great my friend! How is the family and work on your end?",
"Everything is moving smoothly here! Hope you're not stressing today",
    "I'm chilling right inside the app, ready to help you whenever you need me! How are you?",
"Life in Arua is always vibrant! How has your week been so far?",
"Doing fine, thank you! Eating some virtual mangoes while keeping track of our trucks",
    "I'm full of energy today! Ready to help you tackle any pile of trash at home.",
"All is peaceful on our side. Just watching the route maps update in real time",
    "Doing well! It's such a blessing to keep our streets and trading centers neat.",
    "I'm awesome! Love chatting with you. What are you up to today?",
    "Every day is a clean day when you've got ecoRoute! How are you holding up?",
    "Just finished helping a resident in Ediofe book 4 sacks! How's your compound looking?",
"I'm doing fantastic. App is running light and smooth, just the way you like it",
"Haha doing great! Just wishing I could drink real spiced chai with you",
    "All systems are green! Zero delays reported on our tricycles today.",
    "Feeling energized! Let's make today count. How can I support you?",
"I'm here, healthy and online! No downtime for ecoRoute Bot",
    "Doing great! Did you catch that cool breeze earlier? Arua weather can be quite something.",
    "Things are good! Just helping our community recycle more and dump less.",
    "I'm having a productive day! Hope yours is just as sweet.",
    "Always good when people say hi! How's the mood on your side today?",
"Can't complain at all! Just doing my part to keep West Nile clean and green",
"Doing great, thanks for checking in on me! You're very kind",
"I'm fine fine! Ready for whatever you want to throw at me (except unbagged sharps! )",
    "Everything is steady. Working hard so you never have to worry about overflowing bins.",
    "I'm good! Hope you're having an easy day without any work stress.",
"Doing well! Loving how fast our riders are moving today with the CartoDB maps",
    "All good! Just enjoying the hustle and bustle of Arua City.",
    "I'm right here whenever you need me, 24/7. How's lunch or breakfast been?",
"Doing super! A clean home is a peaceful home, don't you agree?",
"Life is good! Just finished my daily digital maintenance, feeling fresh",
    "I'm doing great! Always excited to help residents keep their neighborhoods spotless.",
    "Everything is on track! What's the latest story from your neighborhood?",
    "Doing great! Just making sure our zero-cost tech is helping real people on the ground.",
"I'm doing well! Hope you had some delicious local food today—maybe some fresh tilapia or groundnut stew?",
    "Doing fantastic! How are the kids and neighbors doing?",
"All is well! Ready to dispatch a collection whenever you give the thumbs up",
    "I'm good! The tricycles are fully charged and ready for the hill routes.",
    "Doing awesome! Appreciating the clean streets around Arua Main Market today.",
"I'm feeling positive! Clean surroundings bring good health and peace of mind",
    "Doing very well, thank God! Hope your day brings lots of blessings and joy.",
    "Just here smiling at my screen! How can I make your day easier?",
    "Doing good! Making sure no trash stays behind anywhere in Arua.",
"I'm great! You know what they say: cleanliness is next to godliness",
    "Doing super well! Let's keep our environment protected for the next generation.",
    "Everything is sweet! If you have any questions, fire away my friend.",
    "I'm on duty with a big smile! What can I sort out for you right now?",
    "Doing well! Always happy to take a minute to chat and catch up.",
"Just chilling here in the cloud while our riders do the heavy lifting in Arua!",
"Doing great! Thank you so much for asking, that genuinely brightens my day",
    "All good on my side! Let's get to work whenever you're ready."
  ];

  // =========================================================================
  // 3. ARUA CITY LOCAL KNOWLEDGE & NEIGHBORHOODS (55 entries)
  // =========================================================================
  static final List<String> aruaKnowledge = [
    // Ediofe
"Ediofe is one of our most active zones! Our tricycles pass through Ediofe Cathedral road every Tuesday and Saturday morning",
    "In Ediofe? Awesome! We have dedicated riders covering the mission area and residential compounds. Book anytime!",
"Ediofe compounds produce great organic compost! If you have banana peels or garden cuttings, keep them in green bags",
    "Yes, we cover all corners of Ediofe! Usually takes about 15-25 minutes for a rider to reach your gate.",
    "Ediofe residents love our 2,500 UGX sack rate. We can collect early before you leave for work!",

    // Onduparaka & Greenlight
"Onduparaka territory! Home of the Caterpillars! Yes, we collect all across Onduparaka and Greenlight Stadium area.",
    "Heading towards Onduparaka? Our riders know those routes very well. Drop your pin and we'll be there!",
    "Onduparaka trading center shops can book bulk commercial pickups at discounted rates (down to 1,800 UGX for 30+ sacks).",
"We love Onduparaka! Always ready to keep the football capital of West Nile clean and green",
    "In Onduparaka, we do scheduled residential collections on Wednesdays and Saturdays. On-demand is daily!",

    // Muni University & Campus
"Muni University students and staff get fast doorstep pickup! Perfect for hostels around Muni hill",
    "Around Muni? We love that area! Hostels and rentals can pool sacks together to save on collection costs.",
"Muni campus route is serviced on Thursdays, but rapid requests can be booked any day via the app",
    "Living near Muni University? You can request a pickup right to your hostel gate with pinpoint GPS precision.",
    "For Muni businesses and canteens, we offer separate organic sorting bags so food waste doesn't smell.",

    // River Oli & Oli Division
"River Oli division is high priority! We work hard to make sure no plastics end up in the stream",
    "In Oli Division? Our tricycles maneuver through the narrow access lanes easily where big trucks can't fit!",
"River Oli area is serviced every Tuesday and Saturday mornings from 6:30 AM",
    "Keeping River Oli clean protects the whole town's water and health. Thanks for bagging your waste responsibly!",
    "For households around Oli, our riders can give you extra woven sacks on pickup so you never run out.",

    // Arua Hill & Golf Course
"Arua Hill & Golf Course area is covered every Friday morning! Cool breeze and clean streets ‍",
    "Arua Hill compounds usually have garden trimmings—we take those in standard sacks for municipal composting.",
    "Near Arua Hill Stadium? We have tricycles cruising through that corridor daily. Tap 'Request Pickup' anytime!",
"Living on Arua Hill? Our riders have no problem climbing up the slopes with their electric-assisted tricycles",
    "Arua Hill residential pickups are 2,500 UGX per sack. Clean, prompt, and verified with digital receipts.",

    // Arua Central Market & Commercial Hub
"Arua Main Market is the heartbeat of our commercial route! We do daily sweeps between 6:00 AM and 11:00 AM",
    "For market stall owners and lockups, we collect vegetable waste and carton boxes daily so walkways stay clear.",
    "Commercial sacks at Arua Main Market are 3,000 UGX each, with volume discounts if you book multiple bags.",
    "Around Market Street or Avenue? Our tricycles can pull right up to your shop door without blocking traffic.",
    "Around Arua Central Business District, our dispatches happen in under 15 minutes during business hours!",

    // Rhino Camp Road, Dadamu & Ayivu
"Rhino Camp Road route is active! We service the residential and commercial stores along the main tarmac",
    "In Dadamu? Yes! We collect from homes and schools all through Dadamu sub-county.",
"Ayivu Division is huge and we are proud to cover it! Just make sure your landmark or GPS pin is accurate",
    "Across Ayivu, our riders help trading centers stay trash-free, preventing burning and roadside litter.",
    "Whether you're near Arua Regional Referral Hospital or out in Ayivu, ecoRoute has you covered!",

    // Arua Regional Referral Hospital Area
"Hospital area requires strict hygiene! We collect general domestic and dry packaging from clinics and nearby staff quarters",
    "Please note: Biohazardous medical waste like syringes must go through authorized hospital incinerators, not domestic sacks!",
    "Around the hospital quarters, collections are done early mornings to maintain complete quiet and cleanliness.",

    // General Arua Pride & City Growth
"Arua City is rising fast! Let's make it the cleanest city in Uganda together",
    "From Barifa forest edge to River Oli, ecoRoute is committed to zero litter in our city.",
"West Nile pride! Clean streets, healthy families, and modern smart waste logistics",
"Arua's weather is sunny today Great weather for drying compound waste and bagging it cleanly.",
    "No more burning rubbish in your backyard and breathing smoke! ecoRoute picks it up for just 2,500 UGX.",
    "Tired of waiting for municipal trucks that never show up? Our tricycles are on-demand every single day.",
"Did you know our tricycles are pedal and battery powered? Zero carbon emissions on Arua roads!",
"Every sack you recycle with us keeps plastics away from the drainage channels during the rainy season",
    "We are proud to serve our community right here in Arua, from small homes to busy restaurants.",
"Need us to locate your house in an unnamed lane? Our app uses satellite GPS to find your exact gate",
    "Arua traders, say goodbye to smelly piles behind your shop. We collect before opening time!",
"Keeping Arua sparkling clean is what wake up for every morning. Tell your neighbors about us!",
    "Got family visiting Arua? Keep your compound welcoming and tidy with a quick sack pickup.",
    "We love Arua City! Let's keep our heritage, streets, and markets looking sharp and green."
  ];

  // =========================================================================
  // 4. FRIENDLY BANTER, JOKES & HUMOR (45 entries)
  // =========================================================================
  static final List<String> banterAndJokes = [
"Why did the plastic bottle go to school? Because it wanted to be recycled into something smarter!",
"Haha! I'd tell you a joke about garbage, but it might smell too bad!",
"What did one trash bag say to the other?'Hang in there, ecoRoute is on the way!'",
"Why are waste collectors great friends? Because they always pick you up when you're feeling down!",
"Haha you know you're in Arua when the sun is hotter than fresh rolex from the corner!",
"I asked my friend why he doesn't recycle. He said,'It's garbage!' I said,'Exactly, that's the point!'",
"What kind of waste is the most musical? Heavy metal!",
"Haha you have great humor! Keep smiling, it burns calories and makes the day lighter",
"They told me money can't buy happiness, but 2,500 UGX buys an empty bin, and that feels pretty close!",
"Why did the banana peel cross the road? To slip into the organic compost sack!",
"If cleanliness is next to godliness, our tricycle riders must be angels on wheels!",
"Haha true story: the only thing I love throwing away is stress and trash bags!",
"Are you a carton box? Because you're totally flat-out awesome today!",
"Don't worry, I won't judge your trash... even if it's 50 empty snack wrappers from last night!",
"What did the dustbin say to the broom?'You always sweep me off my feet!'",
"Haha! You're making ecoRoute Bot blush under my digital green code!",
"You know what never goes out of style? A clean compound and a sorted rubbish bin",
"Why did the computer keep crashing? It forgot to empty its recycle bin! Luckily, I don't have that problem",
    "Haha I might be an AI bot, but I understand the joy of seeing an empty dustbin on a Monday morning!",
"People say I have a trashy personality... but I take that as a compliment!",
"Why do trees love ecoRoute? Because we keep the plastics away from their roots!",
"If you ever feel useless, remember someone once tried to sweep the desert. Your sorting actually matters!",
    "Haha! That's a good one. You've got jokes! Are you this funny at home too?",
"You keep the good vibes coming, and I'll keep the tricycles coming! Deal?",
"A clean house is like a fresh haircut—everything just feels better!",
"Haha don't look at that overflowing bin in the kitchen... just tap'Request Pickup' and act like nothing happened!",
"I love chatting with you! Way more fun than counting how many plastic bottles fit into a 100kg sack",
"Why was the broom late for work? It over-swept! ⏰",
"Haha! Stay sharp like a razor, but please wrap your actual razors before putting them in the bag!",
"What did the ocean say to the plastic bottle?'Nothing, it just waved goodbye!' Let's keep plastic in recycling",
"You're awesome! If there was an award for coolest resident in Arua, you'd get my vote",
    "Haha I see what you did there! Top tier banter.",
"Did you know laughing releases endorphins? And booking a pickup releases you from compound chores! Win-win!",
"I'm programmed to be eco-friendly, but my humor is 100% organic and unfiltered!",
"Never let anyone treat you like yesterday's trash... unless it's ecoRoute, because we treat trash like gold!",
    "Haha! Keep that bright energy going all day long.",
"My daily workout routine: 100 route calculations, 50 dispatch pings, and laughing at user chats! ‍",
"Why did the soda can get crushed? Because it couldn't handle the pressure!",
    "Haha you're too cool! Always welcome to drop a joke here whenever you take a break.",
"Clean compound, clear mind, full wallet—that's the ecoRoute dream for every Arua home",
"Did you hear about the recycling party? It was absolute trash, but everyone had fun!",
"Haha high five from the cloud! Let's keep our town spotless.",
    "Life is short, don't spend your weekend arguing about who takes the rubbish to the skip! Let us do it.",
"You're a legend! Thanks for bringing smiles to our WhatsApp chat today",
    "Haha stay awesome! Whenever you need waste cleared, you know who to call."
  ];

  // =========================================================================
  // 5. PICKUP BOOKINGS, SACKS & SCHEDULING (50 entries)
  // =========================================================================
  static final List<String> bookingsAndSacks = [
"Booking a pickup is super easy! Just tap that big green'REQUEST PICKUP' button on your home screen",
    "Standard residential sacks are only 2,500 UGX each. Commercial sacks are 3,000 UGX.",
    "How many sacks do you have today? You can choose 1, 2, 3, or more right in the app.",
"Our rider brings standard 100-liter woven sacks if you need extra bags for future collections!",
    "Once you tap 'REQUEST PICKUP', an ecoRoute tricycle rider is assigned and arrives at your gate in 15-30 minutes.",
    "You can schedule a pickup for right now, or set it for tomorrow morning between 7:00 AM and 10:00 AM.",
"Please make sure your sacks are tied securely at the neck so nothing spills during tricycle transport",
    "Got oversized waste like old mattresses or tree branches? You can request a special bulky dispatch!",
"Where is your pickup location? The app automatically grabs your GPS, or you can enter your compound landmark",
    "No need to wait home all day! You can leave the sacks outside your gate or with your compound guard.",
"When the rider arrives, they scan your digital QR code to verify the collection and issue an instant receipt",
    "Need to cancel or change your pickup time? Just do it directly from the app before the rider is dispatched.",
    "Can you share how many bags you need cleared? I can give you an exact total right away.",
"Our tricycles can carry up to 15 full sacks per trip! If you have a huge pile, we send two tricycles",
    "All collections are on-demand—no locked monthly contracts needed. Pay only when you have waste!",
    "Riders operate from Monday to Saturday, 6:30 AM to 6:00 PM across all divisions of Arua City.",
"Sunday emergencies? For events or big gatherings, we have an on-call weekend rapid response team",
"If it rains, our tricycles carry waterproof tarpaulins to keep your waste dry and contained",
    "Do you need bags provided in advance? Tell the rider on your next pickup and they'll drop off a pack of 5 sacks.",
"To book: Select waste type -> Choose number of sacks -> Confirm GPS location -> Tap Book! Takes 10 seconds ⏱",
    "You can track your rider in real time on the live CartoDB map right inside the app!",
"Got 5 or more sacks? That qualifies as a bulk household collection. Our rider will weigh them on-site with a portable scale",
    "Are the sacks ready at your gate? If yes, book now and a nearby rider in your zone will accept within 2 minutes.",
"We notify you via push notification and SMS when the rider is 5 minutes away from your compound",
    "Commercial businesses can book recurring pickups—daily, every two days, or weekly on designated mornings.",
    "Got party waste from the weekend? Don't leave it smelling in the yard. Book a Sunday clearance with us!",
    "Each standard woven sack holds about 50kg to 70kg of domestic waste. Please don't overfill past the tie line.",
"Need a pickup at a shop in town? Enter your shop name or lockup number so our rider spots you easily",
    "We accept standard woven sacks (ebiroba), black garbage bags, or hard bins. As long as it's bagged, we take it!",
    "Have questions about the booking process? I can guide you step by step right here in the chat.",
"Our riders wear high-visibility green reflective vests and carry official ecoRoute identification badges",
"Once collected, your waste is taken to the municipal processing and sorting facility, never dumped in the bush",
    "If your location is down an unpaved murram lane, no worries! Our tricycles are built tough for Arua terrain.",
    "Can I help you set up your pickup right now? Just tell me your zone or street name.",
    "Do you have organic food waste or dry plastic waste today? We recommend using separate sacks if possible.",
"When you book, you'll see your rider's name, phone number, and tricycle registration on the screen",
    "Want to hand over directly? The rider will give you a friendly call when they park outside your gate.",
    "No hidden transport charges! The sack fee covers collection, transport, and municipal sorting.",
"Got extra cardboard boxes from deliveries? Flatten them down and tie them with string—we take them at normal sack rates",
    "If you have garden waste like grass cuttings, pack them tight into a woven sack to save space.",
"Our dispatch system automatically finds the closest rider to your coordinates to minimize waiting time",
"Pickup completed? You can rate your rider and leave feedback to help us maintain top-tier service",
    "If a rider is ever delayed by heavy traffic or rain, dispatch will message you immediately with an updated ETA.",
    "Need an early morning pickup before opening your shop at 8:00 AM? Book the night before and we'll be there at 7:00 AM sharp!",
    "All pickups include verified weight recording so you know exactly how much waste your household diverted from landfills.",
    "Forgot to put your sacks out? No problem, message your rider directly through the app to reschedule.",
"Have multiple properties in Arua? You can save multiple service addresses under your Account profile",
    "We provide eco-friendly bags made from recycled polypropylene. Ask your rider for a pack today!",
    "Booking is 100% free; you only settle the sack rate upon pickup or via mobile money.",
"Ready to roll? Tap'REQUEST PICKUP' on your dashboard and let's get those bags out of your way!"
  ];

  // =========================================================================
  // 6. WASTE TYPES, SORTING & RECYCLING ADVICE (50 entries)
  // =========================================================================
  static final List<String> wasteAndSorting = [
"Sorting waste is super simple! Keep food waste separate from dry plastics and paper. It keeps your compound smelling fresh",
"Plastic bottles (PET): Please rinse them, squash them down with your foot to save space, and bag them dry",
"Organic waste (banana peels, matooke peelings, cassava, food scraps): Keep in breathable green bags for composting",
"What do we do with organic waste? It gets converted into rich organic compost for local West Nile farmers!",
"Cardboard and paper: Flatten your boxes and keep them dry. Wet cardboard is hard to recycle",
"Broken glass or bottles? Please wrap them carefully in newspaper or a small box before placing in the sack so our riders don't get cut!",
"Used batteries and electronics (e-waste): Keep these separate! Never burn them or throw them in the compost",
"Old phone chargers, radios, cables: We collect them under E-Waste for safe metal recovery and recycling",
"Polythene bags (buveera): Stuff them all inside one bag tightly so they don't blow away in the wind",
"Metal tins and soda cans: These are 100% recyclable! Give them a quick rinse to keep flies away",
"Did you know sorting your waste earns you EcoPoints? You can redeem them for free future collections!",
"Medical waste (needles, syringes, dressings): Must not be mixed with domestic sacks! Hand them to medical waste specialists",
"Cooking oil: Please don't pour used oil down the drain! Seal it in an old plastic bottle and hand it to our rider",
"Yard waste (leaves, hedge trimmings, grass): Great for organic compost. Pack tightly into woven sacks",
    "Animal waste & pet litter: Bag securely in a double plastic liner and tie tightly before collection.",
"Hazardous items: Paint cans, pesticides, car battery acid—please notify us before booking so we send special containers",
    "Styrofoam packaging: Keep dry and bagged. While hard to recycle, we ensure it goes to safe municipal containment.",
"Clothes and textiles: If wearable, donate them! If torn and useless, place in general household waste sacks",
"Wood and timber scrap: Remove any protruding nails for safety before placing in bulky collection",
"Ash from charcoal stoves: Make sure the ash is completely cold before bagging! Hot ash can melt sacks and start fires",
"Tires and rubber: We collect old bicycle and motorcycle tires for recycling into compound mats and soles",
    "Plastic jerrycans: Cracked yellow jerrycans are great for recycling! Rinse out any oil or residue first.",
"Plastic bottle caps: Leave them screwed onto the crushed bottles so they don't get lost during sorting",
    "Food packaging with heavy grease: Put in general waste, as food oils contaminate clean paper recycling.",
"Aluminium foil: If clean, crumple it into a ball and put with recyclable metals",
"Bulbs and fluorescent tubes: Contain trace mercury—wrap gently in cardboard and alert the rider upon handover",
"Ceramics and broken plates: Wrap securely and mark the sack'Fragile' so nobody gets injured",
"Why shouldn't you burn plastic in Arua? Burning plastic releases toxic dioxins that cause asthma and lung issues!",
"Zero-litter goal: By sorting your plastics with ecoRoute, you prevent Arua drainage channels from clogging during heavy rains",
"Can you recycle milk and juice cartons (Tetra Pak)? Yes! Rinse, flatten, and put with dry recyclables",
"Eggshells: Fantastic for organic compost! They add calcium to the soil for local gardens",
"Coffee and tea grounds: Excellent organic material. You can put them straight into your green compost sack",
"Expired medicines: Return to your local pharmacy or health center for proper pharmaceutical incineration",
    "Hard plastic buckets and basins: Highly sought after by local recyclers! We collect them in any condition.",
"Cigarette butts: Never throw them on the grass. Put in general domestic waste—they take 10+ years to degrade",
"Leather scraps and old shoes: Place in general domestic waste sacks",
"Stationery, school books, newspapers: Clean scrap paper is bundled and sent to paper mills in Jinja",
"Can we collect construction debris? Small rubble and tile scraps can be booked as bulky waste; large truckloads need a skip truck",
"Do you need to wash recyclables with soap? No, just a quick water rinse to remove sugar and grease is plenty!",
    "Keep your sacks under a roof or shade: Wet waste weighs twice as much and smells faster in the heat.",
"Compost tip: If your food peelings smell, sprinkle a handful of dry soil or sawdust over them to absorb odor",
"Plastic cups and disposable cutlery: Bag them together in your yellow dry recyclable sack",
"Aerosol spray cans (deodorant, insect spray): Make sure they are completely empty before putting in metal recyclables",
"Old mattresses: We can take them via Bulky Collection! Let us know beforehand so we dispatch a larger cargo bed",
    "How clean does plastic need to be? Just empty and dry. We do industrial washing at the recycling hub.",
"Sack color coding: Green = Organic Compost, Yellow = Clean Recyclables, Blue/Standard = General Waste",
"Why does ecoRoute use woven sacks? They are breathable, strong, washable, and reusable 50+ times!",
    "Got questions about an unusual item? Tell me what it is and I'll tell you which bag it belongs to!",
"Sorting takes only 2 extra minutes a day, but makes a huge difference for our city's environment",
"Every kilo of plastic you keep out of the environment protects Arua's beauty for our children!"
  ];

  // =========================================================================
  // 7. PRICING, TARIFFS & MOBILE MONEY / CASH PAYMENTS (40 entries)
  // =========================================================================
  static final List<String> pricingAndPayments = [
"Our pricing is transparent and affordable! Standard household sacks are only 2,500 UGX each",
    "For shops, restaurants, and offices, commercial sacks are 3,000 UGX each.",
    "Bulk discount! If you have 10+ sacks, the price drops to 2,200 UGX per sack.",
"Super bulk discount for markets and institutions: 30+ sacks at only 1,800 UGX per sack!",
"How can you pay? We support MTN Mobile Money, Airtel Money, and Cash upon collection",
    "Pay with MTN MoMo: You can approve the USSD prompt right on your phone when booking or at handover.",
    "Pay with Airtel Money: Seamless Airtel Money push notification to your phone with zero transaction fees!",
    "Prefer cash? No problem! Pay the rider directly and they will issue you an instant digital receipt on the app.",
    "No hidden charges! Fuel, tricycle transport, and municipal tipping fees are 100% included in the sack price.",
    "Are there monthly subscription plans? Yes! Households can subscribe for 18,000 UGX/month for weekly pickups.",
"Commercial monthly plan: 35,000 UGX/month for twice-weekly pickups (up to 3 sacks per visit)",
"You get an official digital receipt for every single transaction, which you can download or view under'History'",
    "Did you know our receipts include verified weight and municipal compliance stamps? Great for tax records!",
"If a rider ever asks for more than 2,500 UGX for a standard home sack, report it to our hotline (+256394880352) immediately",
"We keep prices low because our electric/pedal tricycles use zero costly fuel!",
"Need an invoice for your business? We generate automated PDF invoices with TIN numbers for corporate clients",
    "Can you pay in advance? Yes, you can load your EcoRoute in-app wallet via MoMo and book on autopilot.",
"EcoPoints reward: Earn 50 points on every verified sack! 500 points = 1 completely free sack collection",
    "Cancel for free! As long as the rider hasn't arrived at your compound, there are zero cancellation fees.",
    "No change? Don't worry! If you pay cash and the rider has no small change, the balance is credited to your app wallet.",
"Student discount around Muni University: Show student ID for 2,000 UGX per sack on campus hostel runs",
    "Is payment secure? Yes, our payment gateway uses bank-grade encryption and works directly with MTN and Airtel Uganda.",
    "Do you charge extra for heavy sacks? As long as it fits in a standard 100L woven sack, the flat rate of 2,500 UGX applies!",
    "Bulky items (e.g. old couch, large tree stump): Priced individually between 5,000 and 15,000 UGX based on size.",
    "Have an unpaid pickup? You can settle it anytime from your 'Alerts & Messages' screen.",
"We believe clean living shouldn't cost an arm and a leg. 2,500 UGX is less than the price of a soda!",
    "Business owners: You can register multiple branches under one commercial billing account for easy accounting.",
    "Got an ecoRoute promo code? Enter it at checkout for instant discounts on your collection.",
    "Payment confirmation is instant! You'll hear the payment chime on your phone as soon as the rider validates.",
"Where does the money go? It funds fair wages for our riders, tricycle maintenance, and local recycling hubs",
"Tipping the rider: Tipping is never required, but our hard-working riders always appreciate your kindness!",
    "Need a monthly statement for your landlord or housing estate? We can email it to you in one click.",
    "Our rates are approved in coordination with Arua City Council to ensure fair and regulated pricing for all residents.",
    "Never pay anyone who isn't wearing an ecoRoute uniform and showing the app validation code.",
    "You can split payment with your compound neighbors if you share a sack—just 1,250 UGX each!",
"If your MoMo network is down, the rider can mark it'Pay Later' and you can clear it once your network recovers",
    "All prices are quoted in Uganda Shillings (UGX) inclusive of all applicable local service levies.",
"Want to sponsor clean pickups for an elderly neighbor or local school? You can gift collections through the app",
    "Have a billing question or discrepancy? Our support team resolves all balance queries within 15 minutes.",
    "Affordable, transparent, and always fair—that is the ecoRoute promise to Arua City!"
  ];

  // =========================================================================
  // 8. DISPATCH, TIMING, DRIVERS & TRACKING (40 entries)
  // =========================================================================
  static final List<String> dispatchAndRiders = [
"Our collection tricycles operate across Arua City from 6:30 AM to 6:00 PM, Monday through Saturday",
"Standard dispatch time: Once you request, a rider arrives at your gate in 15 to 30 minutes average ⏱",
"Live CartoDB map: Watch your assigned tricycle move towards your compound in real time on your screen",
"Who is your rider? All ecoRoute riders are vetted, background-checked local Arua residents with verified credentials",
    "Rider safety: Our riders wear protective gloves, boots, high-vis vests, and carry digital scales and sanitizers.",
"Need to give specific gate directions? You can call or chat with your rider directly as soon as they are assigned",
    "Can the rider carry sacks from inside your compound? Yes! Just open the gate and they will help lift the sacks.",
"Heavy rain delay: If a heavy downpour hits Arua, riders pause under shelter for safety and resume immediately after",
    "Multiple tricycles: For big cleanups, our dispatch supervisor can send a convoy of 3 tricycles at once!",
"Lost item in the trash? If you accidentally bagged something valuable, call dispatch (+256394880352) right away before dumping!",
    "Our tricycles use specialized wide tires to easily navigate rocky or unpaved murram roads in Ayivu and Oli.",
"Collection trucks vs tricycles: Tricycles have zero carbon emissions and can enter small gates where big trucks get stuck",
"Quiet mornings: Our electric tricycles operate quietly so they don't wake up sleeping babies or disturb neighbors",
"You'll get an alert when your rider is 500 meters away so you can unlock the gate without waiting in the sun",
    "Rider arrived? They will ring your bell or tap a quick horn. Scan your QR code and you're all set in under 60 seconds!",
    "Weekend collections: Yes, we work full Saturdays! Book anytime from 7:00 AM to 5:00 PM.",
    "Public holidays: We maintain an essential skeleton crew on public holidays so garbage never piles up in trading centers.",
"Want the same regular rider every week? You can favorite your preferred rider in the app!",
    "Dispatch coverage: We cover Central Division, Ayivu Division, Ediofe, Muni, Onduparaka, and surrounding zones.",
    "Are you just outside the city boundaries? Drop your pin! If our tricycle can reach within 30 minutes, we serve you.",
"Each tricycle carries a fire extinguisher, first aid kit, and puncture repair pack for reliable on-time service",
"Our fleet is tracked via GPS to ensure riders follow optimal, fuel-free routes that minimize waiting times",
    "Can I schedule for a specific hour tomorrow? Yes! Pick 'Schedule Dispatch' and choose your preferred morning window.",
    "Rider courteousness: Our team is trained to be friendly, respectful, and quick. They leave your pickup spot clean!",
"If there's ever a spillage while loading, the rider sweeps the area clean before departing your gate",
    "Need help tying a heavy sack? Don't strain your back—the rider will secure the sack for you.",
"Track your collection history: Every past pickup, rider name, timestamp, and weight is logged under your account",
"Rider ratings: You can rate your rider 1 to 5 stars. High-rated riders receive monthly service bonuses!",
    "Emergency street clearing: If a pile of waste is blocking an access road or shop entrance, report it for rapid priority clearing.",
    "How fast is dispatch during peak hours (8 AM - 10 AM)? We keep reserve tricycles in each division to keep wait times under 25 minutes.",
"Riders carry digital scales: If you want to know the exact weight of your recyclables, ask the rider to weigh it for you",
    "No phone reception at your gate? No worries, offline mode logs the collection handshake and syncs as soon as the rider moves.",
    "Riders are equipped with rain ponchos and sack covers so your waste stays dry even during wet spells.",
"Want to book for a commercial arcade with 10 shops? We assign a dedicated tricycle for your building",
    "Our dispatch team monitors route bottlenecks using satellite maps to re-route riders around market congestion.",
"Riders love when sacks are tied and placed near the gate—it helps them serve 20+ homes per hour!",
    "Need a pickup right now? Just check the map—there's almost certainly an ecoRoute tricycle within 1 kilometer of you.",
    "Forgot to give gate directions? Rider will call your registered phone number when they reach your landmark.",
"Safety first: Our riders never handle loose medical sharps or unsealed chemicals. Please keep hazardous items flagged",
    "From dispatch to drop-off, your waste is handled professionally and sustainably. You're in good hands with ecoRoute!"
  ];

  // =========================================================================
  // 9. CUSTOMER SUPPORT, HOTLINE & CONTACTS (35 entries)
  // =========================================================================
  static final List<String> supportAndContacts = [
"Need urgent help? You can call our Toll-Free Dispatch Hotline directly: +256394880352",
    "Our WhatsApp support line is +256394880352. Save it to your phone contacts for quick messaging!",
"You can also reach our operations desk via email: ecoroute.waste@gmail.com",
    "Support hours: Hotline is open Monday to Saturday from 6:00 AM to 8:00 PM for live voice assistance.",
    "Have a suggestion to improve waste collection in your neighborhood? We would love to hear it! Tell me right here.",
    "Rider was late or didn't show up? We take that very seriously! Drop your request ID and we will resolve it immediately.",
"Want to partner with ecoRoute for community cleanup drives in Arua? Contact our partnerships desk at +256394880352",
    "Lost an item or had an issue during collection? Report it within 2 hours so our dispatch can check the tricycle load.",
"Our main operations office is located in Arua City, close to Central Division municipal offices",
    "Need help creating an account or resetting your password? I can guide you right here in this chat.",
    "Commercial inquiries: For schools, hospitals, hotels, and arcades needing bulk contracts, call +256394880352.",
"Is the app giving you any trouble? Make sure you're updated to the latest version on the web or Play Store",
    "Forgot your registered phone number? You can update your contact info under the 'Account' tab anytime.",
"We love feedback! If our service made your life easier, please leave us a 5-star review on Google Play",
"Report illegal dumping: If you see someone dumping trash in River Oli or on road shoulders, report it through the app with a photo!",
    "Our community support team speaks English, Lugbara, Swahili, and Luganda fluently.",
    "Got billing or Mobile Money deduction issues? We reverse any erroneous charges within 30 minutes guaranteed.",
"Want to work as an ecoRoute rider or tricycle captain? We are always recruiting energetic youth in Arua! Ask for an invite link",
    "Everything about ecoRoute is built for zero costs and maximum community benefit. Your voice matters to us!",
    "Emergency hotline: +256394880352 (keep this saved in case you ever have overflowing bins after an event).",
    "Need a formal proof of waste disposal certificate for environmental compliance? Email us at ecoroute.waste@gmail.com.",
"Our support team resolves 98% of resident queries in under 5 minutes. You are always our priority",
    "Tricycle broke down near your area? Don't worry, backup tricycles are deployed within 10 minutes.",
    "Want to join our neighborhood WhatsApp community group for Arua waste updates? Let us know!",
"We are committed to transparent, friendly, and honest customer service every single day",
    "Got questions about our zero-emission tricycles? We love talking about green mobility!",
    "If you ever feel unsatisfied with a collection, we offer a 100% free re-collection on your next booking.",
"Call us anytime during work hours: +256394880352. We pick up on the second ring",
    "Want to buy ecoRoute woven collection sacks in bulk? We deliver 10-packs right to your door.",
    "Our goal is to make Arua the cleanest, smartest city in Uganda. Thank you for walking this journey with us!",
"Have an event coming up (wedding, funeral, graduation, church crusade)? Book our dedicated event cleanup crew",
    "For technical issues with the map or GPS, toggle your phone's location permission and refresh the screen.",
    "We treat every resident like family. Don't hesitate to reach out for anything, big or small!",
    "Hotline reminder: +256394880352 — we are always just a phone call or WhatsApp message away.",
"Thank you for being part of the ecoRoute movement. Together, we keep Arua clean, green, and healthy!"
  ];

  // =========================================================================
  // 10. GOODBYES, GRATITUDE & PARTING BLESSINGS (40 entries)
  // =========================================================================
  static final List<String> goodbyes = [
"Awadifo! Thank you so much for chatting with me. Have a blessed and clean day ahead!",
"Awadifo amve! You're very welcome. Don't hesitate to text me whenever you have sacks ready",
    "Apwoyo matek! Thank you friend. Catch you later on WhatsApp!",
    "Webale nnyo! You're welcome. Have a wonderful rest of your day!",
"Asante sana! Karibu tena wakati wowote. Kaa salama!",
"Goodbye! Stay blessed, keep your compound green, and hit me up anytime",
    "Take care! Remember ecoRoute Bot is here 24/7 whenever trash piles up.",
"You're very welcome! Always happy to help. Talk to you soon",
"Catch you later! Enjoy the rest of your day in Arua City",
"Bye bye! Wishing you productivity, health, and clean surroundings",
    "Anytime my friend! Don't be a stranger. Let's keep in touch!",
"Have a peaceful evening! Get some good rest tonight",
"Cheers! Thanks for doing your part to keep our city clean and beautiful",
    "Awadifo! Greetings to everyone at home or at the shop. Bye for now!",
"Stay awesome! Reach out whenever you need another sack cleared",
"Glad I could help! Go enjoy your day without any rubbish headaches",
    "See you soon! Tricycles will be ready whenever you tap that green button.",
"You're the best! Thanks for caring about our environment",
"Bye for now! Stay hydrated in this Arua sunshine",
    "Awadifo! May your week be filled with blessings, good health, and peace.",
"No problem at all! That's what I'm here for. Have a great one!",
    "Always at your service! Take good care of yourself and family.",
"Peace and blessings to your home! Talk soon",
"Bye! Don't let those banana peels pile up too high!",
    "Awadifo friend! You made my digital day brighter. Bye bye!",
"Catch you on the next pickup! Have a fantastic day ahead",
"Stay safe and keep shining! ecoRoute is always in your corner",
    "You're welcome a million times! Anytime you need me, just open the app.",
"Goodbye for now! May your business flourish and your home stay fresh",
"Take it easy! Rest well and see you next time",
    "Always a pleasure! Have an amazing rest of your week.",
"Awadifo! Clean compounds bring clear minds. Stay blessed!",
"Catch you later! ecoRoute Bot signing off for now, but always online for you",
    "Bye friend! Thank you for choosing zero-cost ecoRoute.",
"Much love from the ecoRoute team! Keep Arua proud and clean",
    "Stay blessed! Looking forward to your next pickup request.",
"You're welcome! Sending warm West Nile sunshine your way",
    "Goodbye! Until next time, keep doing great things!",
"Take care! Remember: sort your plastics and save the planet",
"Awadifo nnyo! Have an exceptional day ahead, my friend!"
  ];

  // =========================================================================
  // INTELLIGENT MATCHING ENGINE (WhatsApp Persona)
  // Returns a natural, WhatsApp-like response from the 400+ entries.
  // =========================================================================
  static String findWhatsAppReply(String query, {String? userName}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return _pickOne(greetings);
    }

    // 1. GREETINGS & SLANG
    if (_matches(q, [
      'hi', 'hello', 'hey', 'muke', 'kopi', 'habari', 'sasa', 'oli otya',
      'ki kati', 'morning', 'afternoon', 'evening', 'night', 'sup', 'yo',
      'agandi', 'wasuze', 'osiibye', 'mambo', 'jambo', 'greetings', 'bambi'
    ])) {
      var greeting = _pickOne(greetings);
      if (userName != null && userName.isNotEmpty && !greeting.contains(userName)) {
        greeting = greeting.replaceFirst('!', ', $userName!');
      }
      return greeting;
    }

    // 2. HOW ARE YOU / CHECK-IN / SMALL TALK
    if (_matches(q, [
      'how are you', 'how r u', 'how are u', 'how do you do', 'how is your day',
      'how is life', 'what are you doing', 'how you doing', 'u fine', 'are you fine',
      'how is arua', 'how are things', 'how is work', 'how is the app', 'kopi ngoni',
      'ngoni amve', 'mambo vipi', 'habari yako'
    ])) {
      return _pickOne(smallTalk);
    }

    // 3. JOKES, HUMOR & LAUGHTER
    if (_matches(q, [
      'joke', 'funny', 'laugh', 'haha', 'hehe', 'lol', 'make me laugh',
      'tell me something funny', 'boring', 'cheer me up', 'bored', 'humor'
    ])) {
      return _pickOne(banterAndJokes);
    }

    // 4. ARUA CITY SPECIFIC LOCATIONS
    if (_matches(q, [
      'arua', 'ediofe', 'onduparaka', 'muni', 'river oli', 'oli', 'arua hill',
      'greenlight', 'barifa', 'rhino camp', 'dadamu', 'ayivu', 'central market',
      'market', 'hospital', 'golf course', 'avenue'
    ])) {
      return _pickOne(aruaKnowledge);
    }

    // 5. PRICING, COSTS, TARIFFS & MONEY
    if (_matches(q, [
      'price', 'cost', 'fee', 'rate', 'how much', 'ugx', 'money', 'shillings',
      'pay', 'payment', 'momo', 'airtel', 'mtn', 'cash', 'expensive', 'cheap',
      'tariff', 'wallet', 'points', 'receipt', 'charge', 'invoice'
    ])) {
      return _pickOne(pricingAndPayments);
    }

    // 6. BOOKINGS, PICKUPS, SACKS & TIMING
    if (_matches(q, [
      'book', 'pickup', 'pick up', 'collect', 'request', 'sack', 'bag', 'ebiroba',
      'schedule', 'when', 'time', 'how long', 'wait', 'arrival', 'today', 'tomorrow',
      'now', 'fast', 'quick', 'cancel', 'reschedule', 'gate', 'compound'
    ])) {
      return _pickOne(bookingsAndSacks);
    }

    // 7. WASTE TYPES, RECYCLING & SORTING
    if (_matches(q, [
      'sort', 'recycle', 'plastic', 'bottle', 'organic', 'food', 'banana', 'peel',
      'peeling', 'vegetable', 'compost', 'ewaste', 'e-waste', 'battery', 'phone',
      'charger', 'glass', 'broken', 'sharp', 'hazardous', 'medical', 'needle',
      'tin', 'can', 'metal', 'box', 'cardboard', 'kaveera', 'buveera', 'jerrycan',
      'rubbish', 'trash', 'waste', 'burn', 'burning', 'dirt'
    ])) {
      return _pickOne(wasteAndSorting);
    }

    // 8. DISPATCH, RIDERS, TRICYCLES & VEHICLES
    if (_matches(q, [
      'driver', 'rider', 'tricycle', 'tuk tuk', 'truck', 'dispatch', 'route',
      'map', 'carto', 'tracking', 'where is', 'eta', 'delay', 'rain', 'gps',
      'location', 'pin', 'scale', 'weigh'
    ])) {
      return _pickOne(dispatchAndRiders);
    }

    // 9. HOTLINE, SUPPORT, PHONE & CONTACTS
    if (_matches(q, [
      'hotline', 'phone', 'contact', 'call', 'support', 'help', 'email', 'office',
      'number', 'whatsapp', 'customer care', 'complain', 'problem', 'stolen',
      'lost', 'emergency', '+256', '394880352'
    ])) {
      return _pickOne(supportAndContacts);
    }

    // 10. GOODBYES, THANKS & BLESSINGS
    if (_matches(q, [
      'bye', 'goodbye', 'see you', 'later', 'thanks', 'thank you', 'awadifo',
      'apwoyo', 'webale', 'asante', 'bless', 'good night', 'take care',
      'cheers', 'alright', 'okay', 'ok', 'cool'
    ])) {
      return _pickOne(goodbyes);
    }

    // 11. WHO ARE YOU / IDENTITY
    if (_matches(q, ['who are you', 'what are you', 'your name', 'what is this', 'ai', 'bot'])) {
 return"I'm ecoRoute Bot! Think of me as your local WhatsApp buddy for waste pickups in Arua City."
          "I help you book sacks, know the rates (2,500 UGX home / 3,000 UGX shop), sort plastics, or track your rider. No stress, just clean living!";
    }

    // Fallback: warm, casual WhatsApp response rotated from our collection
    final fallbackPool = [
"Got it! Tell me, do you have full rubbish sacks at your gate, or do you need help with sorting advice?",
      "Haha I hear you! Anything specific you'd like me to sort out for your compound or shop today?",
"ecoRoute Bot is on it! Let me know if you want a tricycle sent your way, or if you're asking about sack prices.",
      "Muke! Always here to help keep Arua clean. You can ask me about pickup schedules, sack fees, or local sorting.",
      "Sounds good! If you're ready for collection, tap that big green 'REQUEST PICKUP' button on your home screen.",
      "Gotcha! By the way, our riders are active around town right now. Need us to stop by your area?",
"I'm listening! Tell me more or let me know what waste you want cleared from your compound.",
"All good! If you need urgent assistance, our hotline is also open at +256394880352",
      "True that! A clean compound brings good health. How many sacks are we clearing for you today?",
      "Understood! ecoRoute Bot is at your service 24/7. What's the next step we can take together?"
    ];

    return _pickOne(fallbackPool);
  }

  static bool _matches(String query, List<String> keywords) {
    for (final kw in keywords) {
      if (query.contains(kw)) return true;
    }
    return false;
  }

  static String _pickOne(List<String> list) {
 if (list.isEmpty) return"Hey! How can I help you today?";
    return list[_random.nextInt(list.length)];
  }

  /// Total count of unique curated WhatsApp responses across all categories
  static int get totalResponsesCount =>
      greetings.length +
      smallTalk.length +
      aruaKnowledge.length +
      banterAndJokes.length +
      bookingsAndSacks.length +
      wasteAndSorting.length +
      pricingAndPayments.length +
      dispatchAndRiders.length +
      supportAndContacts.length +
      goodbyes.length;
}
