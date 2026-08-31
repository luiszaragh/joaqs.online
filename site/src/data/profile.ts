/**
 * The settled facts, in one place.
 *
 * This file is the single source for the header, the About section, the
 * résumé-adjacent copy, and — from M5 — the chatbot corpus that the build
 * writes to S3 (DECISIONS.md #20, #29). One source means the bot cannot drift
 * from the page by construction.
 *
 * The domain is deliberately NOT here. It lives in astro.config.mjs `site`
 * and in Terraform's var.domain_name, and nowhere else (DECISIONS.md #25).
 */

export const profile = {
  name: 'Luis Zara',

  /** The masthead uses the full legal-style name (DECISIONS.md #47); the
   * short form stays everywhere identity is compact — the browser tab, the
   * sidebar brand, OG metadata. */
  fullName: 'Luis Joaquin V. Zara',

  /** DECISIONS.md #26 — one label, no slashes. "Junior" does not appear here. */
  role: 'Cloud & DevOps Engineer',

  /** DECISIONS.md #26 — certs first, then the thing recruiters filter on. */
  availability: 'Open to Cloud/DevOps roles — Metro Manila, hybrid, or remote',

  location: {
    city: 'Quezon City',
    region: 'Metro Manila',
    arrangements: ['on-site around Metro Manila', 'hybrid', 'remote'],
  },

  /** DECISIONS.md #19 — goes in About, not the H1.
   *
   * "graduate (May 2026)", not a bare "2026": this line is also the corpus's
   * `education` field, and a year with no verb reads to the model as an
   * expected date — the bot was telling recruiters Luis is still studying. */
  level:
    'BSIT graduate, University of Santo Tomas (May 2026) — open to entry-level and associate roles',

  /**
   * DECISIONS.md #19 — Luis's own words. Use close to verbatim; do not
   * "improve" this into marketing copy.
   */
  intro:
    'My interest in infrastructure started with networking. I liked understanding how ' +
    'devices communicate, what happens behind the scenes when you access a service, and ' +
    'eventually how those same concepts translate into cloud environments.',

  /** DECISIONS.md #19 — the in-progress cert ships, visually separated.
   *
   * #51 — each earned cert carries its official Credly emblem (uploaded to
   * site/public/) and its public verification URL, which is the point of the
   * carousel: not "he says so" but "click through and check". `issued` /
   * `expires` are YYYY-MM strings; null renders as nothing rather than as a
   * made-up date. `tier` colours the carousel accents. */
  certifications: {
    earned: [
      {
        code: 'DOP-C02',
        name: 'AWS Certified DevOps Engineer – Professional',
        tier: 'professional',
        emblem: '/aws-certified-devops-engineer-professional.png',
        credly: 'https://www.credly.com/badges/600ff36d-aea6-49e9-b84f-34dc2a1db502/public_url',
        issued: null as string | null,
        expires: null as string | null,
      },
      {
        code: 'SAA-C03',
        name: 'AWS Certified Solutions Architect – Associate',
        tier: 'associate',
        emblem: '/aws-certified-solutions-architect-associate.png',
        credly: 'https://www.credly.com/badges/cdb04379-554a-47ff-a0a5-c7868348ab8c/public_url',
        issued: null as string | null,
        expires: null as string | null,
      },
      // AWS renamed this credential; SOA-C03 is now CloudOps Engineer, not
      // SysOps Administrator. Matching the résumé matters — a recruiter
      // cross-checking the two should find the same words.
      {
        code: 'SOA-C03',
        name: 'AWS Certified CloudOps Engineer – Associate',
        tier: 'associate',
        emblem: '/aws-certified-cloudops-engineer-associate.png',
        credly: 'https://www.credly.com/badges/5809f1d4-ffc5-47f7-a579-8e8db9de2fad/public_url',
        issued: null as string | null,
        expires: null as string | null,
      },
    ],
    inProgress: [{ code: 'AIF-C01', name: 'AWS Certified AI Practitioner', tier: 'foundational' }],
  },

  /**
   * DECISIONS.md #15 / #28 — the email is published unguarded, click-to-copy,
   * no form and no mailto:. Changing it is a one-line change here.
   */
  email: 'luisjoaquinzara@gmail.com',

  links: {
    github: 'https://github.com/luiszaragh',
    /** TODO: add the real profile URL — nothing is rendered while this is null. */
    linkedin: 'https://www.linkedin.com/in/luis-joaquin-zara/',
  },
} as const;

export type Profile = typeof profile;

/**
 * DECISIONS.md #23 — section 05. The capstone is framed as professional work
 * and lands here once the sanitized summary is written (#18, #35).
 */
export const experience = [
  {
    role: 'Delivery Intern',
    org: 'Noventiq',
    kind: 'Internship',
    start: 'Feb 2026',
    end: 'Jun 2026',
    duration: '5 mos',
    location: 'Philippines · Hybrid',
    bullets: [
      'Developed PowerShell scripts for bulk Microsoft 365 provisioning, UPN-to-alias migration, and SMTP updates for 300+ users and 1,000+ records in a hybrid Microsoft Entra ID environment.',
      'Assisted with testing and troubleshooting Microsoft 365, Entra ID, Intune, Defender, BitLocker, DLP, and SAML SSO in enterprise lab environments.',
    ],
  },
] as const;

/**
 * DECISIONS.md #14 — a card says "I did a thing"; every project also gets a
 * dedicated page: problem, architecture, key decisions, what broke, outcome.
 *
 * #39 / #43 — launch ships with DevSecOps as the only live project. The
 * remaining two are slots with an honest status rather than "coming soon"
 * cards, which #4 rejected as actively costing credibility.
 */
export const projects = [
  {
    slug: 'devsecops-cicd-pipeline',
    title: 'DevSecOps CI/CD pipeline',
    status: 'live',
    summary:
      'A Jenkins pipeline that scans, tests, builds, deploys and observes a containerised app on Kubernetes — fifteen stages, five security and quality tools, and a dashboard fed by the pipeline’s own output.',
    stack: [
      'Jenkins',
      'Docker',
      'Kubernetes',
      'Trivy',
      'Gitleaks',
      'SonarQube',
      'Prometheus',
      'Grafana',
      'Node.js',
    ],
    repo: 'https://github.com/luiszaragh/DevOps-CICD-Pipeline-Project',
  },
  // The EKS three-tier build is off the page for now (2026-08-31). #39/#43
  // designed a slot for it on the understanding that the rework would land;
  // it has not, and a slot advertising work that is not happening is the
  // "coming soon" card #4 rejected. It returns when there is something to
  // link to, not before.
  {
    slug: 'network-capstone',
    title: 'Campus wireless network redesign',
    status: 'live',
    summary:
      'Replaced a flat, unsegmented wireless network at a CPA review centre with a VLAN-segmented one behind a firewall, with RADIUS-backed captive-portal authentication and centrally managed access points.',
    stack: [
      'VLAN segmentation',
      'RADIUS',
      'DHCP',
      'Firewall policy',
      'ACLs',
      'Captive portal',
      'Wireless site survey',
    ],
    repo: null,
  },
] as const;

/**
 * DECISIONS.md #6 — grouped, no proficiency bars. A bar claiming "Terraform
 * 85%" is a number nobody can defend in an interview.
 *
 * Taken from the résumé, which is the source of record, so the site and the
 * PDF a recruiter downloads cannot disagree. The résumé's single "Cloud and
 * Platforms" heading is split in two here only because two platforms on one
 * line reads badly in a definition list; the contents are unchanged.
 *
 * Still absent from the résumé, so still absent here: Prometheus, Grafana,
 * CloudFront, ACM. All are demonstrably used in shipped work, but a site
 * listing skills the résumé does not is a discrepancy a recruiter will notice.
 * Fix the résumé, then this list — in that order.
 */
export const skills = [
  {
    group: 'Programming languages',
    items: ['Java', 'JavaScript', 'PHP', 'Bash', 'HTML', 'CSS', 'Python'],
  },
  {
    group: 'Scripting',
    items: ['Bash', 'PowerShell'],
  },
  {
    group: 'Networking',
    items: ['Cisco', 'AWS networking', 'Windows Server networking', 'TP-Link devices'],
  },
  {
    group: 'Operating systems',
    items: ['Windows', 'Linux', 'macOS'],
  },
  {
    group: 'Cloud — AWS',
    items: ['EC2', 'IAM', 'S3', 'VPC', 'CloudWatch', 'CloudFormation', 'CodeBuild', 'CodeDeploy'],
  },
  {
    group: 'Cloud — Microsoft 365',
    items: ['Entra ID', 'Intune', 'Purview', 'Defender', 'Outlook', 'SharePoint'],
  },
  {
    group: 'Tools',
    items: [
      'Git',
      'GitHub',
      'GitHub Actions',
      'Jenkins',
      'Docker',
      'Kubernetes',
      'SonarQube',
      'Trivy',
      'Cisco Packet Tracer',
      'Claude Code',
      'Terraform',
    ],
  },
] as const;
