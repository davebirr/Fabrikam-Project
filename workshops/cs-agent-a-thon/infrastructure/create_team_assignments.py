#!/usr/bin/env python3
"""
Create balanced team assignments for CS Agent-a-thon workshop
- Advanced participants grouped together (3-4 teams)
- Beginner/Intermediate mixed (remaining teams)
- No-preference participants distributed evenly
"""

import csv
import random
from collections import defaultdict

# Set seed for reproducibility
random.seed(42)

# Read participant assignments
participants = {}
with open('participant-assignments.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        email = row['RealEmail'].lower()
        participants[email] = row

# Read survey responses
survey = {}
with open('challenge-survey-responses.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        email = row['Email'].lower()
        survey[email] = row['ChallengeLevel']

# Categorize participants
beginner_pref = []
intermediate_pref = []
advanced_pref = []
no_pref = []

for email, data in participants.items():
    entry = {
        'email': email,
        'name': data['RealFullName'],
        'alias': data['RealAlias'],
        'user_num': data['UserNumber'],
        'original_team': data['Team'],
        'country': data['Country']
    }
    
    if email in survey:
        pref = survey[email]
        if pref == 'Beginner':
            beginner_pref.append(entry)
        elif pref == 'Intermediate':
            intermediate_pref.append(entry)
        elif pref == 'Advanced':
            advanced_pref.append(entry)
    else:
        no_pref.append(entry)

# Shuffle for random distribution
random.shuffle(beginner_pref)
random.shuffle(intermediate_pref)
random.shuffle(advanced_pref)
random.shuffle(no_pref)

print("=== WORKSHOP TEAM ASSIGNMENTS ===\n")
print(f"Total Participants: {len(participants)}")
print(f"  - Beginner preference: {len(beginner_pref)}")
print(f"  - Intermediate preference: {len(intermediate_pref)}")
print(f"  - Advanced preference: {len(advanced_pref)}")
print(f"  - No preference: {len(no_pref)}")
print()

# Team assignments
teams = defaultdict(list)
team_types = {}

# Assign advanced participants to teams 1-4
team_num = 1
advanced_per_team = (len(advanced_pref) + 3) // 4  # Distribute across 4 teams
for i, participant in enumerate(advanced_pref):
    team_id = ((i // advanced_per_team) + 1)
    if team_id > 4:
        team_id = 4
    teams[team_id].append({**participant, 'preference': 'Advanced'})
    team_types[team_id] = 'Advanced'

# Distribute beginner and intermediate across teams 5-20 (16 teams)
mixed_teams = list(range(5, 21))
all_mixed = beginner_pref + intermediate_pref

# Distribute no-preference evenly across mixed teams
no_pref_per_mixed_team = len(no_pref) // len(mixed_teams)
no_pref_remainder = len(no_pref) % len(mixed_teams)

# Add no-pref to mixed pool
for i in range(len(mixed_teams)):
    num_to_add = no_pref_per_mixed_team + (1 if i < no_pref_remainder else 0)
    for j in range(num_to_add):
        if no_pref:
            all_mixed.append(no_pref.pop(0))

random.shuffle(all_mixed)

# Distribute mixed participants across teams 5-20
participants_per_mixed_team = len(all_mixed) // len(mixed_teams)
mixed_remainder = len(all_mixed) % len(mixed_teams)

idx = 0
for team_id in mixed_teams:
    num_for_this_team = participants_per_mixed_team + (1 if (team_id - 5) < mixed_remainder else 0)
    for i in range(num_for_this_team):
        if idx < len(all_mixed):
            participant = all_mixed[idx]
            pref = 'No Preference'
            if participant in beginner_pref:
                pref = 'Beginner'
            elif participant in intermediate_pref:
                pref = 'Intermediate'
            teams[team_id].append({**participant, 'preference': pref})
            idx += 1
    team_types[team_id] = 'Mixed (Beg/Int)'

# Output team assignments
print("\n=== TEAM COMPOSITION ===\n")
for team_id in sorted(teams.keys()):
    members = teams[team_id]
    print(f"Team {team_id:02d} ({team_types[team_id]}) - {len(members)} members")
    
    # Count preferences
    pref_counts = defaultdict(int)
    for member in members:
        pref_counts[member['preference']] += 1
    
    pref_summary = ", ".join([f"{k}: {v}" for k, v in sorted(pref_counts.items())])
    print(f"  Preferences: {pref_summary}")
    
    for member in members:
        print(f"    - {member['name']:30s} ({member['alias']:15s}) [{member['preference']}]")
    print()

# Write to CSV
output_file = 'team-assignments-balanced.csv'
with open(output_file, 'w', newline='', encoding='utf-8') as f:
    fieldnames = ['TeamNumber', 'TeamType', 'UserNumber', 'RealFullName', 'RealAlias', 'RealEmail', 
                  'OriginalTeam', 'Country', 'ChallengePreference']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    
    for team_id in sorted(teams.keys()):
        for member in teams[team_id]:
            writer.writerow({
                'TeamNumber': team_id,
                'TeamType': team_types[team_id],
                'UserNumber': member['user_num'],
                'RealFullName': member['name'],
                'RealAlias': member['alias'],
                'RealEmail': member['email'],
                'OriginalTeam': member['original_team'],
                'Country': member['country'],
                'ChallengePreference': member['preference']
            })

print(f"\n✅ Team assignments written to: {output_file}")

# Summary statistics
print("\n=== SUMMARY STATISTICS ===")
print(f"Advanced-focused teams: {len([t for t in team_types.values() if t == 'Advanced'])}")
print(f"Mixed (Beg/Int) teams: {len([t for t in team_types.values() if t != 'Advanced'])}")
print()

team_sizes = [len(teams[t]) for t in teams.keys()]
print(f"Team sizes: Min={min(team_sizes)}, Max={max(team_sizes)}, Avg={sum(team_sizes)/len(team_sizes):.1f}")
