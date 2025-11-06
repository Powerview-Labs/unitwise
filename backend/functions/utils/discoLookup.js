/**
 * DISCO & BAND LOOKUP UTILITY
 * 
 * Provides distribution company (DisCo) and tariff band lookup
 * based on Nigerian geographical locations
 * 
 * DATA SOURCE: Nigerian Electricity Regulatory Commission (NERC)
 * LAST UPDATED: November 2025
 * 
 * SECURITY NOTES:
 * - Static lookup data (no database queries)
 * - Input validation and sanitization
 * - No sensitive user data processed
 */

/**
 * Nigeria Distribution Companies (DisCos)
 * Complete list of all 11 electricity distribution companies
 */
const DISCO_LIST = [
  { code: 'AEDC', name: 'Abuja Electricity Distribution Company', region: 'North Central' },
  { code: 'BEDC', name: 'Benin Electricity Distribution Company', region: 'South South' },
  { code: 'EEDC', name: 'Enugu Electricity Distribution Company', region: 'South East' },
  { code: 'EKEDP', name: 'Eko Electricity Distribution Company', region: 'South West' },
  { code: 'IBEDC', name: 'Ibadan Electricity Distribution Company', region: 'South West' },
  { code: 'IE', name: 'Ikeja Electric', region: 'South West' },
  { code: 'JED', name: 'Jos Electricity Distribution Company', region: 'North Central' },
  { code: 'KAEDC', name: 'Kaduna Electricity Distribution Company', region: 'North West' },
  { code: 'KEDCO', name: 'Kano Electricity Distribution Company', region: 'North West' },
  { code: 'PHED', name: 'Port Harcourt Electricity Distribution Company', region: 'South South' },
  { code: 'YEDC', name: 'Yola Electricity Distribution Company', region: 'North East' },
];

/**
 * Tariff Bands with typical supply hours per day
 * Based on NERC Multi-Year Tariff Order (MYTO)
 */
const TARIFF_BANDS = {
  A: { supplyHours: 20, description: 'Minimum 20 hours supply per day' },
  B: { supplyHours: 16, description: 'Minimum 16 hours supply per day' },
  C: { supplyHours: 12, description: 'Minimum 12 hours supply per day' },
  D: { supplyHours: 8, description: 'Minimum 8 hours supply per day' },
  E: { supplyHours: 4, description: 'Minimum 4 hours supply per day' },
};

/**
 * State to DisCo mapping
 * Handles states with single DisCo coverage
 */
const STATE_TO_DISCO = {
  // AEDC Coverage
  'FCT': 'AEDC',
  'Nasarawa': 'AEDC',
  'Kogi': 'AEDC', // Note: Some parts IBEDC (overlap state)
  'Niger': 'AEDC', // Note: Some parts IBEDC (overlap state)
  
  // BEDC Coverage
  'Edo': 'BEDC',
  'Delta': 'BEDC',
  'Ondo': 'BEDC',
  'Ekiti': 'BEDC', // Note: Some parts IE (overlap state)
  
  // EEDC Coverage
  'Enugu': 'EEDC',
  'Anambra': 'EEDC',
  'Abia': 'EEDC',
  'Imo': 'EEDC',
  'Ebonyi': 'EEDC',
  
  // EKEDP Coverage (Lagos Island, Lekki, VI, Ajah, etc.)
  // Note: Lagos is split between IE and EKEDP
  
  // IBEDC Coverage
  'Oyo': 'IBEDC',
  'Osun': 'IBEDC',
  'Kwara': 'IBEDC',
  
  // IE Coverage (Lagos Mainland - Ikeja, Agege, Oshodi, etc.)
  // Note: Lagos is split between IE and EKEDP
  
  // JED Coverage
  'Plateau': 'JED',
  'Benue': 'JED',
  'Bauchi': 'JED',
  'Gombe': 'JED',
  
  // KAEDC Coverage
  'Kaduna': 'KAEDC',
  'Kebbi': 'KAEDC',
  'Sokoto': 'KAEDC',
  'Zamfara': 'KAEDC',
  
  // KEDCO Coverage
  'Kano': 'KEDCO',
  'Katsina': 'KEDCO',
  'Jigawa': 'KEDCO',
  
  // PHED Coverage
  'Rivers': 'PHED',
  'Bayelsa': 'PHED',
  'Cross River': 'PHED',
  'Akwa Ibom': 'PHED',
  
  // YEDC Coverage
  'Adamawa': 'YEDC',
  'Borno': 'YEDC',
  'Taraba': 'YEDC',
  'Yobe': 'YEDC',
};

/**
 * Lagos-specific area mapping (overlap state)
 * Lagos is split between Ikeja Electric and Eko Electricity
 */
const LAGOS_AREAS = {
  IE: [
    'Ikeja', 'Agege', 'Oshodi', 'Ikorodu', 'Shomolu', 'Mushin',
    'Surulere', 'Yaba', 'Abule Egba', 'Akowonjo', 'Ogba', 'Ojodu',
    'Berger', 'Ketu', 'Maryland', 'Anthony', 'Gbagada', 'Bariga',
    'Fadeyi', 'Jibowu', 'Palmgrove', 'Onipanu', 'Ilupeju', 'Isolo',
    'Ejigbo', 'Iju', 'Ifako', 'Alakuko', 'Alagbado', 'Meiran',
  ],
  EKEDP: [
    'Lagos Island', 'Victoria Island', 'Ikoyi', 'Lekki', 'Ajah',
    'Apapa', 'Festac', 'Amuwo Odofin', 'Ojo', 'Satellite Town',
    'Trade Fair', 'Mile 2', 'Badagry', 'Ibeju-Lekki', 'Epe',
    'Marina', 'CMS', 'Obalende', 'Falomo', 'Onikan', 'Dolphin',
  ],
};

/**
 * Niger State area mapping (overlap state)
 * Split between AEDC and IBEDC
 */
const NIGER_AREAS = {
  AEDC: [
    'Minna', 'Suleja', 'Bida', 'Kontagora', 'New Bussa',
  ],
  IBEDC: [
    'Borgu', // Near Kwara border
  ],
};

/**
 * Kogi State area mapping (overlap state)
 * Split between AEDC and IBEDC
 */
const KOGI_AREAS = {
  AEDC: [
    'Lokoja', 'Okene', 'Ajaokuta', 'Ankpa', 'Idah', 'Dekina',
  ],
  IBEDC: [
    'Kabba', 'Ijumu', 'Yagba East', 'Yagba West',
  ],
};

/**
 * Ekiti State area mapping (overlap state)
 * Primarily BEDC with some IE coverage
 */
const EKITI_AREAS = {
  BEDC: [
    'Ado-Ekiti', 'Ikere', 'Efon', 'Ijero', 'Ikole', 'Emure',
  ],
  IE: [
    'Ise-Orun', // Near Ondo/Ekiti border
  ],
};

/**
 * Ogun State area mapping (overlap state)
 * Primarily IBEDC with EKEDP in Agbara Industrial Estate
 */
const OGUN_AREAS = {
  IBEDC: [
    'Abeokuta', 'Sagamu', 'Ijebu-Ode', 'Ota', 'Ifo', 'Ilaro',
  ],
  EKEDP: [
    'Agbara', // Industrial Estate
  ],
};

/**
 * Lookup DisCo based on state and optional area
 * 
 * @param {string} state - State name
 * @param {string} area - Optional area/city name for overlap states
 * @return {Object} { success: boolean, disco?: string, requiresArea?: boolean }
 */
function lookupDisco(state, area = null) {
  // Normalize input
  const normalizedState = state.trim();
  
  // Handle overlap states
  if (normalizedState === 'Lagos') {
    if (!area) {
      return {
        success: false,
        requiresArea: true,
        message: 'Lagos has multiple DisCos. Please specify your area.',
        areas: [...LAGOS_AREAS.IE, ...LAGOS_AREAS.EKEDP],
      };
    }
    
    // Check which DisCo serves this area
    const normalizedArea = area.trim();
    
    if (LAGOS_AREAS.IE.some(a => normalizedArea.toLowerCase().includes(a.toLowerCase()))) {
      return { success: true, disco: 'IE', fullName: 'Ikeja Electric' };
    }
    
    if (LAGOS_AREAS.EKEDP.some(a => normalizedArea.toLowerCase().includes(a.toLowerCase()))) {
      return { success: true, disco: 'EKEDP', fullName: 'Eko Electricity Distribution Company' };
    }
    
    // Default to IE for unknown Lagos areas
    return { success: true, disco: 'IE', fullName: 'Ikeja Electric', assumed: true };
  }
  
  if (normalizedState === 'Niger') {
    if (!area) {
      return {
        success: false,
        requiresArea: true,
        message: 'Niger State has multiple DisCos. Please specify your area.',
        areas: [...NIGER_AREAS.AEDC, ...NIGER_AREAS.IBEDC],
      };
    }
    
    const normalizedArea = area.trim();
    
    if (NIGER_AREAS.AEDC.some(a => normalizedArea.toLowerCase().includes(a.toLowerCase()))) {
      return { success: true, disco: 'AEDC', fullName: 'Abuja Electricity Distribution Company' };
    }
    
    if (NIGER_AREAS.IBEDC.some(a => normalizedArea.toLowerCase().includes(a.toLowerCase()))) {
      return { success: true, disco: 'IBEDC', fullName: 'Ibadan Electricity Distribution Company' };
    }
    
    // Default to AEDC for unknown Niger areas
    return { success: true, disco: 'AEDC', fullName: 'Abuja Electricity Distribution Company', assumed: true };
  }
  
  if (normalizedState === 'Kogi') {
    if (!area) {
      return {
        success: false,
        requiresArea: true,
        message: 'Kogi State has multiple DisCos. Please specify your area.',
        areas: [...KOGI_AREAS.AEDC, ...KOGI_AREAS.IBEDC],
      };
    }
    
    const normalizedArea = area.trim();
    
    if (KOGI_AREAS.AEDC.some(a => normalizedArea.toLowerCase().includes(a.toLowerCase()))) {
      return { success: true, disco: 'AEDC', fullName: 'Abuja Electricity Distribution Company' };
    }
    
    if (KOGI_AREAS.IBEDC.some(a => normalizedArea.toLowerCase().includes(a.toLowerCase()))) {
      return { success: true, disco: 'IBEDC', fullName: 'Ibadan Electricity Distribution Company' };
    }
    
    // Default to AEDC
    return { success: true, disco: 'AEDC', fullName: 'Abuja Electricity Distribution Company', assumed: true };
  }
  
  if (normalizedState === 'Ekiti') {
    if (!area) {
      return { success: true, disco: 'BEDC', fullName: 'Benin Electricity Distribution Company' };
    }
    
    const normalizedArea = area.trim();
    
    if (EKITI_AREAS.IE.some(a => normalizedArea.toLowerCase().includes(a.toLowerCase()))) {
      return { success: true, disco: 'IE', fullName: 'Ikeja Electric' };
    }
    
    return { success: true, disco: 'BEDC', fullName: 'Benin Electricity Distribution Company' };
  }
  
  if (normalizedState === 'Ogun') {
    if (!area) {
      return { success: true, disco: 'IBEDC', fullName: 'Ibadan Electricity Distribution Company' };
    }
    
    const normalizedArea = area.trim();
    
    if (normalizedArea.toLowerCase().includes('agbara')) {
      return { success: true, disco: 'EKEDP', fullName: 'Eko Electricity Distribution Company' };
    }
    
    return { success: true, disco: 'IBEDC', fullName: 'Ibadan Electricity Distribution Company' };
  }
  
  // Single-DisCo states
  const disco = STATE_TO_DISCO[normalizedState];
  
  if (disco) {
    const discoInfo = DISCO_LIST.find(d => d.code === disco);
    return {
      success: true,
      disco: disco,
      fullName: discoInfo ? discoInfo.name : disco,
    };
  }
  
  return {
    success: false,
    message: 'State not found. Please check spelling or select manually.',
  };
}

/**
 * Get typical tariff band for an area (estimation logic)
 * 
 * NOTE: This is a simplified estimation. In production, integrate with
 * NERC API or user-provided band from meter bill.
 * 
 * @param {string} disco - DisCo code
 * @param {string} area - Area/location name
 * @return {string} Estimated band (A-E)
 */
function estimateBand(disco, area) {
  // Default to Band C (12 hours) for most areas
  // In production, this should be user-confirmable or fetched from NERC data
  
  // High-supply areas (typically Band A or B)
  const highSupplyAreas = [
    'Victoria Island', 'Ikoyi', 'Lekki Phase 1', 'Banana Island',
    'Asokoro', 'Maitama', 'Wuse 2', 'Garki', 'Central Area',
  ];
  
  if (highSupplyAreas.some(a => area.toLowerCase().includes(a.toLowerCase()))) {
    return 'B'; // Assume Band B (16 hours)
  }
  
  // Default assumption
  return 'C'; // Band C (12 hours) is most common
}

/**
 * Get all available DisCos
 * 
 * @return {Array} List of all DisCos
 */
function getAllDiscos() {
  return DISCO_LIST;
}

/**
 * Get all tariff bands
 * 
 * @return {Object} Tariff bands with supply hours
 */
function getAllBands() {
  return TARIFF_BANDS;
}

/**
 * Validate DisCo code
 * 
 * @param {string} disco - DisCo code
 * @return {boolean} True if valid DisCo
 */
function isValidDisco(disco) {
  return DISCO_LIST.some(d => d.code === disco);
}

/**
 * Validate tariff band
 * 
 * @param {string} band - Band letter (A-E)
 * @return {boolean} True if valid band
 */
function isValidBand(band) {
  return band in TARIFF_BANDS;
}

/**
 * Get supply hours for a band
 * 
 * @param {string} band - Band letter (A-E)
 * @return {number} Supply hours per day
 */
function getSupplyHours(band) {
  return TARIFF_BANDS[band]?.supplyHours || 12; // Default to Band C
}

module.exports = {
  lookupDisco,
  estimateBand,
  getAllDiscos,
  getAllBands,
  isValidDisco,
  isValidBand,
  getSupplyHours,
  DISCO_LIST,
  TARIFF_BANDS,
};
