-- ============================================
-- Create Tables
-- ============================================

CREATE TABLE Disaster (
    Disaster_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Date] DATE NOT NULL,
    [Type] VARCHAR(50) NOT NULL,
    Population_Affected INT NOT NULL,
    Location VARCHAR(100) NOT NULL,
    [Status] VARCHAR(20) NOT NULL
);

CREATE TABLE IncidentReport (
    Report_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Disaster_ID INT NOT NULL FOREIGN KEY REFERENCES Disaster(Disaster_ID),
    Description VARCHAR(500),
    Date_Reported DATE NOT NULL,
    Reported_By VARCHAR(100) NOT NULL
);

-- Include Disaster_ID in ResponseTeam to link each team to a single disaster
CREATE TABLE ResponseTeam (
    Team_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Team_Name VARCHAR(100) NOT NULL,
    Personnel_Count INT NOT NULL,
    Specialization VARCHAR(100) NOT NULL,
    Disaster_ID INT NOT NULL FOREIGN KEY REFERENCES Disaster(Disaster_ID)
);

CREATE TABLE PublicHealthData (
    HealthData_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Disaster_ID INT NOT NULL FOREIGN KEY REFERENCES Disaster(Disaster_ID),
    Disease_Outbreak BIT NOT NULL,
    Hospitalization INT NOT NULL,
    Casualties INT NOT NULL
);

CREATE TABLE FinancialAid (
    Aid_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Disaster_ID INT NOT NULL FOREIGN KEY REFERENCES Disaster(Disaster_ID),
    Amount DECIMAL(15,2) NOT NULL,
    Date_Issued DATE NOT NULL,
    [Source] VARCHAR(100) NOT NULL
);

CREATE TABLE Resource (
    Resource_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Resource_Type VARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    Allocation_Status VARCHAR(50) NOT NULL,
    Allocation_Date DATE NOT NULL,
    Disaster_ID INT NOT NULL FOREIGN KEY REFERENCES Disaster(Disaster_ID)
);

-- ============================================
-- Insert Data
-- ============================================

INSERT INTO Disaster ([Date], [Type], Population_Affected, Location, [Status])
VALUES
('2021-07-15', 'Flood', 2000, 'New Orleans, USA', 'Resolved'),
('2022-03-10', 'Earthquake', 5000, 'Tokyo, Japan', 'Ongoing'),
('2023-01-22', 'Hurricane', 3000, 'Miami, USA', 'Resolved');

INSERT INTO IncidentReport (Disaster_ID, Description, Date_Reported, Reported_By)
VALUES
(1, 'Flooded streets in downtown area', '2021-07-16', 'John Doe'),
(1, 'Residential area basement flooding', '2021-07-17', 'Local Resident'),
(2, 'Collapsed building in city center', '2022-03-11', 'City Official'),
(2, 'Aftershock caused additional cracks in older buildings', '2022-03-12', 'Survey Team'),
(3, 'High winds damaged multiple roofs', '2023-01-23', 'Homeowner'),
(3, 'Power lines down across the region', '2023-01-24', 'Electric Company');

-- Now each team is assigned to a particular disaster
INSERT INTO ResponseTeam (Team_Name, Personnel_Count, Specialization, Disaster_ID)
VALUES
('Red Cross Team A', 20, 'Medical Assistance', 1), -- Deployed to Disaster_ID=1
('FEMA Search Unit', 15, 'Search and Rescue', 2), -- Deployed to Disaster_ID=2
('Local Fire Brigade', 10, 'Firefighting and Rescue', 3); -- Deployed to Disaster_ID=3

INSERT INTO PublicHealthData (Disaster_ID, Disease_Outbreak, Hospitalization, Casualties)
VALUES
(1, 0, 20, 2),
(2, 1, 100, 30),
(3, 0, 50, 5);

INSERT INTO FinancialAid (Disaster_ID, Amount, Date_Issued, [Source])
VALUES
(1, 50000.00, '2021-07-20', 'Local Government'),
(1, 25000.00, '2021-07-22', 'Red Cross'),
(2, 100000.00, '2022-03-15', 'International Relief Fund'),
(2, 75000.00, '2022-03-18', 'UN Aid'),
(3, 60000.00, '2023-01-25', 'FEMA'),
(3, 20000.00, '2023-01-27', 'Local Charity');

INSERT INTO Resource (Resource_Type, Quantity, Allocation_Status, Allocation_Date, Disaster_ID)
VALUES
('Bottled Water', 1000, 'Allocated', '2021-07-18', 1),
('Sandbags', 500, 'Allocated', '2021-07-19', 1),
('Tents', 300, 'Allocated', '2022-03-13', 2),
('Blankets', 600, 'Allocated', '2022-03-14', 2),
('Generators', 50, 'Allocated', '2023-01-26', 3),
('Tarps', 200, 'Allocated', '2023-01-26', 3);

-- ============================================
-- Queries
-- ============================================

-- Q1: How many disasters occurred in a specific location within a given year? (Analyst, Administrator)
SELECT COUNT(*) AS DisasterCount
FROM Disaster
WHERE Location = 'Tokyo, Japan'
  AND YEAR([Date]) = 2022;

-- Q2: Which disaster had the highest number of people affected? (Witness query - Analyst)
SELECT TOP 1 Disaster_ID, [Type], Population_Affected, Location, [Date]
FROM Disaster
ORDER BY Population_Affected DESC;

-- Q3: What is the total amount of financial aid provided for a given disaster? (Administrator)
-- Example: Disaster_ID = 2
SELECT d.Disaster_ID, d.[Type], SUM(f.Amount) AS TotalAid
FROM Disaster d
JOIN FinancialAid f ON d.Disaster_ID = f.Disaster_ID
WHERE d.Disaster_ID = 2
GROUP BY d.Disaster_ID, d.[Type];

-- Q4: What are the names of response teams deployed to a specific disaster? (Administrator)
-- Now we can just join ResponseTeam to Disaster using Disaster_ID since it's a direct FK.
-- Example: Disaster_ID = 1
SELECT rt.Team_Name
FROM ResponseTeam rt
WHERE rt.Disaster_ID = 1;

-- Q5: How many resources were allocated for a specific disaster? (Logistics Manager)
-- Example: Disaster_ID = 3
SELECT d.Disaster_ID, COUNT(*) AS ResourceCount
FROM Disaster d
JOIN Resource r ON d.Disaster_ID = r.Disaster_ID
WHERE d.Disaster_ID = 3
GROUP BY d.Disaster_ID;

-- Q6: Which disasters had both a disease outbreak and casualties reported? (Self-join - Analyst)
-- With the given data, this can be done in a single join:
SELECT DISTINCT d.Disaster_ID, d.[Type], d.Location, d.[Date]
FROM Disaster d
JOIN PublicHealthData p ON d.Disaster_ID = p.Disaster_ID
WHERE p.Disease_Outbreak = 1 AND p.Casualties > 0;

-- Q7: What is the ranking of disasters by the number of hospitalizations reported? (Ranking query - Analyst)
SELECT d.Disaster_ID, d.[Type], d.Location, p.Hospitalization,
       RANK() OVER (ORDER BY p.Hospitalization DESC) AS HospitalizationRank
FROM Disaster d
JOIN PublicHealthData p ON d.Disaster_ID = p.Disaster_ID;

-- Q8: How many incident reports have been generated for disasters in a given month? (Administrator)
-- Example: March 2022
SELECT YEAR(Date_Reported) AS ReportYear, MONTH(Date_Reported) AS ReportMonth, COUNT(*) AS IncidentCount
FROM IncidentReport
WHERE YEAR(Date_Reported) = 2022
  AND MONTH(Date_Reported) = 3
GROUP BY YEAR(Date_Reported), MONTH(Date_Reported);

-- Q9: Which resource type is allocated most frequently across all disasters? (Logistics Manager, Analyst)
SELECT TOP 1 Resource_Type, COUNT(*) AS AllocationCount
FROM Resource
GROUP BY Resource_Type
ORDER BY COUNT(*) DESC;

-- Q10: What is the status of resources allocated to a specific disaster? (Logistics Manager)
-- Example: Disaster_ID = 2
SELECT r.Resource_Type, r.Allocation_Status
FROM Resource r
WHERE r.Disaster_ID = 2;