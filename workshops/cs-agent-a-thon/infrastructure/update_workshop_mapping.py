#!/usr/bin/env python3
"""
Update workshop-user-mapping.csv with new team assignments from teams-final.csv
- Updates TeamNumber and ChallengeLevel from teams-final.csv
- Ensures all users have unique fictitious names
- Assigns new fictitious names to any users without them
"""

import csv
from collections import defaultdict

# Read teams-final.csv to get updated team assignments and preferences
print("Reading teams-final.csv...")
team_assignments = {}
with open('teams-final.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        email = row['RealEmail'].lower()
        team_assignments[email] = {
            'team': row['TeamNumber'],
            'challenge_level': row['ChallengePreference']
        }

print(f"Found {len(team_assignments)} team assignments")

# Read existing workshop-user-mapping.csv
print("\nReading workshop-user-mapping.csv...")
users = []
user_by_email = {}
with open('workshop-user-mapping.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        users.append(row)
        user_by_email[row['RealEmail'].lower()] = row

print(f"Found {len(users)} users in workshop mapping")

# Read available fictitious names from FNF files
print("\nReading fictitious names from FNF files...")
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

print(f"Found {len(available_names)} available fictitious names")

# Track which names are already used
used_names = set()
for user in users:
    if user['FictitiousFullName']:
        used_names.add(user['FictitiousFullName'])

print(f"Found {len(used_names)} names already in use")

# Create index of available unused names
unused_names = [name for name in available_names if name['full'] not in used_names]
print(f"Found {len(unused_names)} unused names available")

# Update users with new team assignments and challenge levels
print("\nUpdating user records...")
updates_made = 0
names_assigned = 0
name_index = 0

for user in users:
    email = user['RealEmail'].lower()
    
    # Update team assignment and challenge level if user is in teams-final
    if email in team_assignments:
        old_team = user['Team']
        old_level = user['ChallengeLevel']
        
        user['Team'] = team_assignments[email]['team']
        user['ChallengeLevel'] = team_assignments[email]['challenge_level']
        
        if old_team != user['Team'] or old_level != user['ChallengeLevel']:
            updates_made += 1
            print(f"  Updated {user['RealFullName']:30s} - Team: {old_team:3s} -> {user['Team']:3s}, Level: {old_level:15s} -> {user['ChallengeLevel']}")
    
    # Assign fictitious name if user doesn't have one and we have names available
    if not user['FictitiousFullName'] and name_index < len(unused_names):
        name = unused_names[name_index]
        user['FictitiousFirstName'] = name['first']
        user['FictitiousLastName'] = name['last']
        user['FictitiousFullName'] = name['full']
        user['FictitiousGender'] = name['gender']
        user['FictitiousLanguage'] = name['language']
        
        # Generate alias and email
        first_clean = ''.join(c for c in name['first'] if c.isalnum())
        last_clean = ''.join(c for c in name['last'] if c.isalnum())
        alias = f"{first_clean}{last_clean[0]}" if last_clean else first_clean
        
        user['DisplayName'] = name['full']
        user['Alias'] = alias
        user['NativeUserPrincipalName'] = f"{alias}@fabrikam1.csplevelup.com"
        
        names_assigned += 1
        name_index += 1
        print(f"  Assigned name to {user['RealFullName']:30s} -> {name['full']}")

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
print(f"  - Team/Level updates: {updates_made}")
print(f"  - New names assigned: {names_assigned}")
print(f"  - Total users: {len(users)}")
print(f"  - Users with teams: {len([u for u in users if u['Team'] and u['Team'] != 'team-00'])}")
print(f"  - Proctors (team-00): {len([u for u in users if u['Team'] == 'team-00'])}")
