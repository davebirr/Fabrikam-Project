#!/usr/bin/env python3
"""
Add missing participants (Yara Chia and Jason Thorwall) to workshop-user-mapping.csv
"""

import csv

# Read existing workshop-user-mapping.csv
print("Reading workshop-user-mapping.csv...")
users = []
with open('workshop-user-mapping.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        users.append(row)

print(f"Found {len(users)} existing users")

# Get next user numbers
existing_numbers = [int(u['UserNumber']) for u in users]
next_user_number = max(existing_numbers) + 1

print(f"Next user number: {next_user_number}")

# Read available fictitious names
print("\nReading fictitious names...")
available_names = []
fnf_files = [
    'FNF-2025-10-28-00059-0262.csv',
    'FNF-2025-10-28-00060-0901.csv'
]

for fnf_file in fnf_files:
    try:
        with open(fnf_file, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                available_names.append({
                    'first': row['FirstName'],
                    'last': row['LastName'],
                    'full': row['FullName'],
                    'gender': row['Gender'],
                    'language': row['Language']
                })
    except FileNotFoundError:
        print(f"  Warning: {fnf_file} not found, skipping...")

# Track which names are already used
used_names = set()
for user in users:
    if user['FictitiousFullName']:
        used_names.add(user['FictitiousFullName'])

# Get unused names
unused_names = [name for name in available_names if name['full'] not in used_names]
print(f"Found {len(unused_names)} unused names available")

# Add Jason Thorwall
if unused_names:
    name = unused_names[0]
    first_clean = ''.join(c for c in name['first'] if c.isalnum())
    last_clean = ''.join(c for c in name['last'] if c.isalnum())
    alias = f"{first_clean}{last_clean[0]}" if last_clean else first_clean
    
    jason = {
        'UserNumber': str(next_user_number),
        'RealFullName': 'Jason Thorwall',
        'RealAlias': 'JATHORWA',
        'RealEmail': 'jathorwa@microsoft.com',
        'Team': 'TBD',  # Not yet assigned to a team
        'Country': 'United States',
        'Role': 'Participant',
        'ChallengeLevel': 'Intermediate',
        'FictitiousFirstName': name['first'],
        'FictitiousLastName': name['last'],
        'FictitiousFullName': name['full'],
        'FictitiousGender': name['gender'],
        'FictitiousLanguage': name['language'],
        'NativeUserPrincipalName': f"{alias}@fabrikam1.csplevelup.com",
        'DisplayName': name['full'],
        'Alias': alias
    }
    users.append(jason)
    next_user_number += 1
    print(f"\n✅ Added Jason Thorwall (User {jason['UserNumber']}) -> {name['full']}")

# Add Yara Chia (as auditor, not in a team)
if len(unused_names) > 1:
    name = unused_names[1]
    first_clean = ''.join(c for c in name['first'] if c.isalnum())
    last_clean = ''.join(c for c in name['last'] if c.isalnum())
    alias = f"{first_clean}{last_clean[0]}" if last_clean else first_clean
    
    yara = {
        'UserNumber': str(next_user_number),
        'RealFullName': 'Yara Chia',
        'RealAlias': 'YARACHIA',
        'RealEmail': 'yara.chia@outlook.com',
        'Team': 'Auditor',  # Not in a participant team
        'Country': 'Unknown',
        'Role': 'Auditor',
        'ChallengeLevel': 'Beginner',  # From survey
        'FictitiousFirstName': name['first'],
        'FictitiousLastName': name['last'],
        'FictitiousFullName': name['full'],
        'FictitiousGender': name['gender'],
        'FictitiousLanguage': name['language'],
        'NativeUserPrincipalName': f"{alias}@fabrikam1.csplevelup.com",
        'DisplayName': name['full'],
        'Alias': alias
    }
    users.append(yara)
    print(f"✅ Added Yara Chia (User {yara['UserNumber']}) -> {name['full']} [AUDITOR - Not in teams]")

# Write updated workshop-user-mapping.csv
print(f"\nWriting updated workshop-user-mapping.csv...")
with open('workshop-user-mapping.csv', 'w', newline='', encoding='utf-8') as f:
    fieldnames = [
        'UserNumber', 'RealFullName', 'RealAlias', 'RealEmail', 'Team', 'Country',
        'Role', 'ChallengeLevel', 'FictitiousFirstName', 'FictitiousLastName',
        'FictitiousFullName', 'FictitiousGender', 'FictitiousLanguage',
        'NativeUserPrincipalName', 'DisplayName', 'Alias'
    ]
    writer = csv.DictWriter(f, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
    writer.writeheader()
    writer.writerows(users)

print(f"\n✅ Workshop mapping updated successfully!")
print(f"\nSummary:")
print(f"  - Total users now: {len(users)}")
print(f"  - Participants in teams: {len([u for u in users if u['Team'].isdigit()])}")
print(f"  - Proctors: {len([u for u in users if u['Role'] == 'Proctor'])}")
print(f"  - Auditors: {len([u for u in users if u['Role'] == 'Auditor'])}")
print(f"  - Pending team assignment: {len([u for u in users if u['Team'] == 'TBD'])}")
