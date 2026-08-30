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

  /** DECISIONS.md #26 — one label, no slashes. "Junior" does not appear here. */
  role: 'Cloud & DevOps Engineer',

  /** DECISIONS.md #26 — certs first, then the thing recruiters filter on. */
  availability: 'Open to Cloud/DevOps roles — Metro Manila, hybrid, or remote',

  location: {
    city: 'Quezon City',
    region: 'Metro Manila',
    arrangements: ['on-site around Metro Manila', 'hybrid', 'remote'],
  },

  /** DECISIONS.md #19 — goes in About, not the H1. */
  level: 'BSIT, University of Santo Tomas, 2026 — open to entry-level and associate roles',

  /**
   * DECISIONS.md #19 — Luis's own words. Use close to verbatim; do not
   * "improve" this into marketing copy.
   */
  intro:
    'My interest in infrastructure started with networking. I liked understanding how ' +
    'devices communicate, what happens behind the scenes when you access a service, and ' +
    'eventually how those same concepts translate into cloud environments.',

  /** DECISIONS.md #19 — the in-progress cert ships, visually separated. */
  certifications: {
    earned: [
      { code: 'DOP-C02', name: 'AWS Certified DevOps Engineer – Professional' },
      { code: 'SAA-C03', name: 'AWS Certified Solutions Architect – Associate' },
      { code: 'SOA-C03', name: 'AWS Certified SysOps Administrator – Associate' },
    ],
    inProgress: [{ code: 'AIF-C01', name: 'AWS Certified AI Practitioner' }],
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
  {
    slug: 'aws-eks-three-tier',
    title: 'Three-tier application on EKS',
    status: 'rework',
    statusNote: 'Being rewritten so the infrastructure is the subject, not the app.',
    summary:
      'Terraform-provisioned EKS with IRSA, Secrets Manager, ACM, health probes, non-root containers, and a budget-alarm auto-pause Lambda.',
    stack: ['Terraform', 'EKS', 'RDS', 'IRSA', 'Secrets Manager', 'ACM'],
    repo: null,
  },
  {
    slug: 'network-capstone',
    title: 'Network design capstone',
    status: 'pending',
    statusNote: 'Publishing a sanitized summary — no real topology, addressing, or client name.',
    summary:
      'Role-based network segmentation and centralised authentication for a review centre serving 500+ users.',
    stack: ['VLAN segmentation', 'RADIUS', 'DHCP', 'Firewall policy'],
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
 * Deliberately NOT added: Terraform, Prometheus, Grafana, CloudFront, ACM.
 * They are demonstrably used in shipped work but are absent from the résumé,
 * and inventing a discrepancy between the two documents is worse than an
 * incomplete list. See the note in DECISIONS.md open threads.
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
    ],
  },
] as const;
