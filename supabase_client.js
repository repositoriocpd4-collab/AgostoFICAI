/**
 * Cliente de Integração Supabase - FICAI 4.0
 * Conexão direta com o Supabase usando as chaves configuradas
 * Suporte completo a Alunos, FICAIs, Histórico, Documentos Anexados e Storage
 */

const SUPABASE_URL = 'https://ojvxsrvmmkjxfgyczypm.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_JDPRSMCStt58M2CWLfNHtA_F1zuxvvG';
const STORAGE_BUCKET_DOCS = 'ficai-documentos';

// Inicialização do cliente Supabase (requer @supabase/supabase-js incluído no HTML)
let supabaseClient = null;

function getSupabase() {
  if (supabaseClient) return supabaseClient;
  if (typeof window !== 'undefined' && window.supabase && window.supabase.createClient) {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    return supabaseClient;
  }
  return null;
}

// Serviços para Alunos (Students)
const StudentService = {
  async getAll() {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb.from('students').select('*').order('nome');
    if (error) throw error;
    return data;
  },

  async upsert(student) {
    const sb = getSupabase();
    if (!sb) return null;
    const payload = {
      key: student.key,
      nome: student.nome,
      social: student.social || '',
      nascimento: student.nascimento || null,
      cpf: student.cpf || '',
      rg: student.rg || '',
      filiacao: student.filiacao || '',
      responsavel: student.responsavel || '',
      residencia: student.residencia || '',
      telefone: student.telefone || '',
      referencia: student.referencia || '',
      updated_at: new Date().toISOString()
    };
    const { data, error } = await sb.from('students').upsert(payload, { onConflict: 'key' }).select();
    if (error) throw error;
    return data?.[0];
  }
};

// Serviços para Documentos e Anexos da FICAI
const DocumentService = {
  /**
   * Upload de arquivo binário diretamente para o bucket de storage do Supabase
   * @param {File|Blob} file Objeto do arquivo selecionado
   * @param {string} ficaiNumero Número da FICAI (ex: '00021/2026')
   * @param {string} customName Nome customizado opcional
   */
  async uploadStorageFile(file, ficaiNumero, customName = '') {
    const sb = getSupabase();
    if (!sb) return null;

    const cleanNum = (ficaiNumero || 'geral').replace(/[\/\\]/g, '-');
    const ext = (file.name ? file.name.split('.').pop() : 'bin').toLowerCase();
    const uniqueId = (typeof crypto !== 'undefined' && crypto.randomUUID) ? crypto.randomUUID() : ('file-' + Date.now());
    const filePath = `${cleanNum}/${uniqueId}.${ext}`;

    const { data, error } = await sb.storage
      .from(STORAGE_BUCKET_DOCS)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: true,
        contentType: file.type || 'application/octet-stream'
      });

    if (error) {
      console.warn('Falha no upload para o Supabase Storage:', error);
      throw error;
    }

    const { data: publicUrlData } = sb.storage
      .from(STORAGE_BUCKET_DOCS)
      .getPublicUrl(filePath);

    return {
      path: filePath,
      fullPath: data?.fullPath || filePath,
      publicUrl: publicUrlData?.publicUrl || '',
      fileName: customName || file.name || `${uniqueId}.${ext}`,
      size: file.size,
      mime: file.type,
      ext: ext
    };
  },

  /**
   * Registra um documento na tabela public.ficai_documentos
   */
  async addDocument(doc) {
    const sb = getSupabase();
    if (!sb) return null;

    const payload = {
      id: doc.id || ('doc-' + (typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Date.now())),
      ficai_numero: doc.ficai_numero || doc.ficaiNumero,
      entry_id: doc.entry_id || doc.entryId || null,
      nome_arquivo: doc.nome_arquivo || doc.name || 'Documento Anexo',
      tipo_documento: doc.tipo_documento || doc.type || 'Documento',
      extensao: (doc.extensao || doc.ext || 'pdf').toLowerCase(),
      mime_type: doc.mime_type || doc.mime || 'application/octet-stream',
      tamanho_bytes: doc.tamanho_bytes || doc.size || 0,
      arquivo_url: doc.arquivo_url || doc.url || doc.data || '',
      storage_path: doc.storage_path || doc.path || '',
      responsavel: doc.responsavel || doc.responsible || 'Usuário',
      descricao: doc.descricao || doc.description || doc.text || '',
      data_documento: doc.data_documento || doc.date || new Date().toISOString().split('T')[0],
      updated_at: new Date().toISOString()
    };

    const { data, error } = await sb.from('ficai_documentos').insert(payload).select();
    if (error) {
      console.warn('Erro ao inserir documento no Supabase:', error);
      throw error;
    }
    return data?.[0];
  },

  /**
   * Busca todos os documentos vinculados a uma FICAI
   */
  async getDocuments(ficaiNumero) {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb
      .from('ficai_documentos')
      .select('*')
      .eq('ficai_numero', ficaiNumero)
      .order('data_documento', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  /**
   * Remove um documento e opcionalmente o arquivo do Storage
   */
  async deleteDocument(docId, storagePath = '') {
    const sb = getSupabase();
    if (!sb) return false;

    if (storagePath) {
      try {
        await sb.storage.from(STORAGE_BUCKET_DOCS).remove([storagePath]);
      } catch (errStorage) {
        console.warn('Não foi possível remover arquivo do Storage:', errStorage);
      }
    }

    const { error } = await sb.from('ficai_documentos').delete().eq('id', docId);
    if (error) throw error;
    return true;
  }
};

// Serviços para FICAIs e Linha do Tempo / Histórico
function buildCtWorkflowSnapshot(record = {}, baseData = {}) {
  const status = record.statusTramitacaoCT || record.status_tramitacao_ct || baseData?.__ctWorkflow?.status || 'CRIADA';
  return {
    ...(baseData || {}),
    __ctWorkflow: {
      ...(baseData?.__ctWorkflow || {}),
      status,
      isSent: !!(record.isEncaminhadoCT || record.is_encaminhado_ct || status !== 'CRIADA'),
      hasReturn: !!(record.hasDevolutivaCT || record.has_devolutiva_ct || status === 'DEVOLVIDA_PELO_CT'),
      sentAt: record.ctEnviadoEm || record.ct_enviado_em || null,
      sentBy: record.ctEnviadoPor || record.ct_enviado_por || '',
      viewedAt: record.ctVisualizadoEm || record.ct_visualizado_em || null,
      viewedBy: record.ctVisualizadoPor || record.ct_visualizado_por || '',
      returnedAt: record.ctDevolvidoEm || record.ct_devolvido_em || null,
      returnedBy: record.ctDevolvidoPor || record.ct_devolvido_por || ''
    }
  };
}

function mergeCtWorkflowData(baseData = {}, updates = {}) {
  return {
    ...(baseData || {}),
    __ctWorkflow: {
      ...(baseData?.__ctWorkflow || {}),
      ...updates
    }
  };
}

const FicaiService = {
  async getAll(filters = {}) {
    const sb = getSupabase();
    if (!sb) return [];

    let query = sb.from('ficais').select('*, ficai_info_entries(*)').order('updated_at', { ascending: false });
    // Para usuários de escola, evita baixar registros de outras unidades quando o filtro é informado.
    if (filters.escola) query = query.eq('escola', filters.escola);
    if (Array.isArray(filters.statusTramitacaoCT) && filters.statusTramitacaoCT.length) {
      query = query.in('status_tramitacao_ct', filters.statusTramitacaoCT);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  },

  async getByNumero(numero) {
    const sb = getSupabase();
    if (!sb) return null;
    const { data, error } = await sb
      .from('ficais')
      .select('*, ficai_info_entries(*), ficai_documentos(*)')
      .eq('numero', numero)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async upsert(record) {
    const sb = getSupabase();
    if (!sb) return null;

    const persistedData = buildCtWorkflowSnapshot(record, record.data || {});

    const payload = {
      numero: record.numero,
      ano: record.ano,
      student_key: record.studentKey || record.student_key,
      aluno: record.aluno,
      escola: record.escola,
      turma: record.turma,
      situacao: record.situacao || 'Infrequente',
      data: persistedData,
      status_fluxo: record.status_fluxo || 'aberto',

      // Tramitação Escola <-> Conselho Tutelar. Mantém a mesma FICAI durante todo o ciclo.
      section: record.section || 'GERADOS',
      status_tramitacao_ct: record.statusTramitacaoCT || record.status_tramitacao_ct || 'CRIADA',
      is_encaminhado_ct: !!(record.isEncaminhadoCT || record.is_encaminhado_ct),
      has_devolutiva_ct: !!(record.hasDevolutivaCT || record.has_devolutiva_ct),
      ct_enviado_em: record.ctEnviadoEm || record.ct_enviado_em || null,
      ct_enviado_por: record.ctEnviadoPor || record.ct_enviado_por || null,
      ct_visualizado_em: record.ctVisualizadoEm || record.ct_visualizado_em || null,
      ct_visualizado_por: record.ctVisualizadoPor || record.ct_visualizado_por || null,
      ct_devolvido_em: record.ctDevolvidoEm || record.ct_devolvido_em || null,
      ct_devolvido_por: record.ctDevolvidoPor || record.ct_devolvido_por || null,
      updated_at: new Date().toISOString()
    };

    let result = await sb.from('ficais').upsert(payload, { onConflict: 'numero' }).select();

    // Compatibilidade: se o SQL de migração ainda não tiver sido executado, preserva o CRUD legado.
    // O fluxo CT continuará local até a migração ser aplicada, sem quebrar as funcionalidades atuais.
    if (result.error && (result.error.code === 'PGRST204' || result.error.code === '42703')) {
      console.warn('Colunas de tramitação CT ainda não existem no Supabase. Usando payload legado até aplicar MIGRACAO_FLUXO_CT.sql.');
      const legacyPayload = {
        numero: record.numero,
        ano: record.ano,
        student_key: record.studentKey || record.student_key,
        aluno: record.aluno,
        escola: record.escola,
        turma: record.turma,
        situacao: record.situacao || 'Infrequente',
        data: persistedData,
        status_fluxo: record.status_fluxo || 'aberto',
        updated_at: new Date().toISOString()
      };
      result = await sb.from('ficais').upsert(legacyPayload, { onConflict: 'numero' }).select();
    }

    if (result.error) throw result.error;
    const data = result.data;

    // Se houver histórico local com entradas/documentos, sincroniza com as tabelas relacionais
    if (Array.isArray(record.infoEntries) && record.infoEntries.length) {
      for (const entry of record.infoEntries) {
        try {
          await this.addInfoEntry({
            ...entry,
            ficai_numero: record.numero
          });
        } catch (_syncErr) {
          // Ignora duplicidades na sincronização
        }
      }
    }

    return data?.[0];
  },

  async addInfoEntry(entry) {
    const sb = getSupabase();
    if (!sb) return null;

    const attachmentsList = Array.isArray(entry.attachments) ? entry.attachments : [];

    const payload = {
      id: entry.id || ('reg-' + (typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Date.now())),
      ficai_numero: entry.ficai_numero || entry.ficaiNumero,
      date: entry.date,
      type: entry.type || 'Acompanhamento',
      entry_kind: entry.entryKind || entry.entry_kind || (attachmentsList.length ? 'document' : 'info'),
      text: entry.text || '',
      responsible: entry.responsible || 'Usuário',
      attachments: attachmentsList,
      is_devolutiva: !!(entry.isDevolutiva || entry.is_devolutiva),
      action: entry.action || null,
      updated_at: new Date().toISOString()
    };

    let result = await sb.from('ficai_info_entries').upsert(payload, { onConflict: 'id' }).select();
    if (result.error && (result.error.code === 'PGRST204' || result.error.code === '42703')) {
      // Compatibilidade com o schema anterior, que ainda não possuía a coluna action.
      const { action, ...legacyPayload } = payload;
      result = await sb.from('ficai_info_entries').upsert(legacyPayload, { onConflict: 'id' }).select();
    }
    const { data, error } = result;
    if (error) {
      console.warn('Erro ao inserir registro de histórico no Supabase:', error);
      throw error;
    }

    // Se houver anexos nesta entrada, registrar também na tabela dedicada public.ficai_documentos
    if (attachmentsList.length) {
      for (const att of attachmentsList) {
        try {
          await DocumentService.addDocument({
            id: att.id,
            ficai_numero: payload.ficai_numero,
            entry_id: payload.id,
            nome_arquivo: att.name,
            tipo_documento: entry.type || 'Documento',
            extensao: att.ext || 'pdf',
            mime_type: att.mime || 'application/octet-stream',
            tamanho_bytes: att.size || 0,
            arquivo_url: att.url || att.data || '',
            storage_path: att.path || '',
            responsavel: payload.responsible,
            descricao: payload.text || att.name,
            data_documento: payload.date
          });
        } catch (errDoc) {
          console.warn('Erro ao espelhar anexo em ficai_documentos:', errDoc);
        }
      }
    }

    return data?.[0];
  },

  /**
   * Registra de forma idempotente a PRIMEIRA visualização da FICAI pelo Conselho Tutelar.
   * Usa RPC atômica quando a migração está instalada e possui fallback para instalações antigas.
   */
  async markCtViewed(numero, { viewedAt = new Date().toISOString(), viewedBy = 'Conselho Tutelar' } = {}) {
    const sb = getSupabase();
    if (!sb || !numero) return null;

    try {
      const { data, error } = await sb.rpc('ficai_marcar_visualizacao_ct', {
        p_ficai_numero: numero,
        p_visualizado_em: viewedAt,
        p_visualizado_por: viewedBy
      });
      if (!error) {
        const row = Array.isArray(data) ? data[0] : data;
        return { record: row || null };
      }
      if (!['PGRST202', '42883'].includes(error.code)) throw error;
    } catch (err) {
      if (!['PGRST202', '42883'].includes(err?.code)) console.warn('RPC primeira visualização CT indisponível:', err);
    }

    // Fallback sem RPC: lê antes e só grava se ainda não houver visualização.
    const { data: current, error: readError } = await sb.from('ficais').select('*').eq('numero', numero).maybeSingle();
    if (readError) throw readError;
    if (!current) return { record: null };
    const currentWorkflow = current.data?.__ctWorkflow || {};
    if (current.ct_visualizado_em || currentWorkflow.viewedAt) return { record: current };

    const { data, error } = await sb.from('ficais').update({
      status_tramitacao_ct: 'VISUALIZADA_PELO_CT',
      is_encaminhado_ct: true,
      section: 'GERADOS',
      status_fluxo: 'conselho_tutelar',
      ct_visualizado_em: viewedAt,
      ct_visualizado_por: viewedBy,
      updated_at: viewedAt
    }).eq('numero', numero).is('ct_visualizado_em', null).select();

    if (error) {
      if (error.code === 'PGRST204' || error.code === '42703') {
        // Instalações sem as novas colunas ainda persistem o fluxo no JSON `data`,
        // permitindo que Escola e CT compartilhem o mesmo estado em dispositivos diferentes.
        const legacyData = mergeCtWorkflowData(current.data || {}, {
          status: 'VISUALIZADA_PELO_CT',
          isSent: true,
          hasReturn: false,
          sentAt: currentWorkflow.sentAt || current.ct_enviado_em || null,
          sentBy: currentWorkflow.sentBy || current.ct_enviado_por || '',
          viewedAt,
          viewedBy,
          returnedAt: null,
          returnedBy: ''
        });
        const { data: legacyRows, error: legacyError } = await sb.from('ficais').update({
          data: legacyData,
          status_fluxo: 'conselho_tutelar',
          updated_at: viewedAt
        }).eq('numero', numero).select();
        if (legacyError) throw legacyError;
        return { record: legacyRows?.[0] || { ...current, data: legacyData }, legacy: true };
      }
      throw error;
    }
    return { record: data?.[0] || current };
  },

  /**
   * Devolve formalmente a FICAI para a escola sem criar novo registro.
   * A operação é idempotente: uma segunda chamada não gera nova tramitação.
   */
  async returnFromCt(numero, { returnedAt = new Date().toISOString(), returnedBy = 'Conselho Tutelar' } = {}) {
    const sb = getSupabase();
    if (!sb || !numero) return null;

    try {
      const { data, error } = await sb.rpc('ficai_devolver_para_escola', {
        p_ficai_numero: numero,
        p_devolvido_em: returnedAt,
        p_devolvido_por: returnedBy
      });
      if (!error) {
        const row = Array.isArray(data) ? data[0] : data;
        return { record: row || null };
      }
      if (!['PGRST202', '42883'].includes(error.code)) throw error;
    } catch (err) {
      if (!['PGRST202', '42883'].includes(err?.code)) console.warn('RPC devolução CT indisponível:', err);
    }

    const { data: current, error: readError } = await sb.from('ficais').select('*').eq('numero', numero).maybeSingle();
    if (readError) throw readError;
    if (!current) return { record: null };
    const currentWorkflow = current.data?.__ctWorkflow || {};
    if (current.status_tramitacao_ct === 'DEVOLVIDA_PELO_CT' || currentWorkflow.status === 'DEVOLVIDA_PELO_CT') return { record: current };

    const { data, error } = await sb.from('ficais').update({
      status_tramitacao_ct: 'DEVOLVIDA_PELO_CT',
      is_encaminhado_ct: true,
      has_devolutiva_ct: true,
      section: 'RECEBIDOS_CT',
      status_fluxo: 'em_analise',
      ct_devolvido_em: returnedAt,
      ct_devolvido_por: returnedBy,
      updated_at: returnedAt
    }).eq('numero', numero).neq('status_tramitacao_ct', 'DEVOLVIDA_PELO_CT').select();

    if (error) {
      if (error.code === 'PGRST204' || error.code === '42703') {
        const legacyData = mergeCtWorkflowData(current.data || {}, {
          status: 'DEVOLVIDA_PELO_CT',
          isSent: true,
          hasReturn: true,
          sentAt: currentWorkflow.sentAt || current.ct_enviado_em || null,
          sentBy: currentWorkflow.sentBy || current.ct_enviado_por || '',
          viewedAt: currentWorkflow.viewedAt || current.ct_visualizado_em || null,
          viewedBy: currentWorkflow.viewedBy || current.ct_visualizado_por || '',
          returnedAt,
          returnedBy
        });
        const { data: legacyRows, error: legacyError } = await sb.from('ficais').update({
          data: legacyData,
          status_fluxo: 'em_analise',
          updated_at: returnedAt
        }).eq('numero', numero).select();
        if (legacyError) throw legacyError;
        return { record: legacyRows?.[0] || { ...current, data: legacyData }, legacy: true };
      }
      throw error;
    }
    return { record: data?.[0] || current };
  },

  async getInfoEntries(ficaiNumero) {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb
      .from('ficai_info_entries')
      .select('*')
      .eq('ficai_numero', ficaiNumero)
      .order('date', { ascending: false });

    if (error) throw error;
    return data || [];
  }
};

// Serviços para Marcadores (Tags)
const MarcadorService = {
  async getCatalog() {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb.from('marcadores').select('*').eq('ativo', true).order('nome');
    if (error) throw error;
    return data;
  },

  async addMarcadorToCatalog(name, color) {
    const sb = getSupabase();
    if (!sb) return null;
    const { data, error } = await sb.from('marcadores').upsert({ nome: name, cor: color, ativo: true }, { onConflict: 'nome' }).select();
    if (error) throw error;
    return data?.[0];
  },

  async getStudentTags(ficaiNumero) {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb.from('student_tags').select('*').eq('ficai_numero', ficaiNumero);
    if (error) throw error;
    return data;
  },

  async addStudentTag(ficaiNumero, studentKey, tagNome, tagCor, texto) {
    const sb = getSupabase();
    if (!sb) return null;
    const payload = {
      ficai_numero: ficaiNumero,
      student_key: studentKey,
      tag_nome: tagNome,
      tag_cor: tagCor,
      texto: texto || ''
    };
    const { data, error } = await sb.from('student_tags').insert(payload).select();
    if (error) throw error;
    return data?.[0];
  },

  async removeStudentTag(ficaiNumero, tagNome) {
    const sb = getSupabase();
    if (!sb) return null;
    if (tagNome === '__ALL__') {
      const { error } = await sb.from('student_tags').delete().eq('ficai_numero', ficaiNumero);
      if (error) throw error;
    } else {
      const { error } = await sb.from('student_tags').delete().eq('ficai_numero', ficaiNumero).eq('tag_nome', tagNome);
      if (error) throw error;
    }
    return true;
  }
};

// Serviços para Escolas
const EscolaService = {
  async getAll() {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb.from('escolas').select('*').order('nome');
    if (error) throw error;
    return data;
  },

  async bulkUpsert(escolasArray) {
    const sb = getSupabase();
    if (!sb) return null;
    const { data, error } = await sb.from('escolas').upsert(escolasArray, { onConflict: 'nome' }).select();
    if (error) throw error;
    return data;
  }
};

// Serviços para Registro Permanente de Cancelamentos
const CancelamentoService = {
  async getAll() {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb.from('cancelamentos_ficais').select('*').order('data_cancelamento', { ascending: false });
    if (error) throw error;
    return data;
  },

  async insert(record) {
    const sb = getSupabase();
    if (!sb) return null;
    const payload = {
      ficai_numero: record.ficai_numero || record.ficai,
      aluno_nome: record.aluno_nome || record.aluno || record.student,
      escola_nome: record.escola_nome || record.escola,
      turma: record.turma,
      motivo: record.motivo,
      justificativa: record.justificativa,
      responsavel: record.responsavel,
      data_cancelamento: record.data_cancelamento || new Date().toISOString()
    };
    const { data, error } = await sb.from('cancelamentos_ficais').insert(payload).select();
    if (error) throw error;
    return data?.[0];
  }
};

const LogService = {
  async getAll(limit = 300) {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb
      .from('system_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit);
    if (error) {
      console.warn('Erro ao carregar logs do Supabase:', error);
      return [];
    }
    return (data || []).map(item => ({
      id: item.id,
      level: item.level || 'update',
      action: item.action || 'Evento do Sistema',
      description: item.description || '',
      user: item.user_email || item.user || 'Sistema',
      details: item.details || {},
      timestamp: item.created_at
    }));
  },

  async add(logEntry) {
    const sb = getSupabase();
    if (!sb) return null;
    const payload = {
      id: logEntry.id || ('log-' + Date.now() + '-' + Math.floor(Math.random() * 10000)),
      level: logEntry.level || 'update',
      action: logEntry.action || 'Evento do Sistema',
      description: logEntry.description || '',
      user_email: logEntry.user || logEntry.user_email || 'Sistema',
      details: logEntry.details || {},
      created_at: logEntry.timestamp || new Date().toISOString()
    };
    const { data, error } = await sb.from('system_logs').insert([payload]).select();
    if (error) {
      console.warn('Erro ao salvar log no Supabase:', error);
      return null;
    }
    return data?.[0];
  },

  async clearAll() {
    const sb = getSupabase();
    if (!sb) return false;
    const { error } = await sb.from('system_logs').delete().neq('id', '0');
    if (error) {
      console.warn('Erro ao limpar logs do Supabase:', error);
      return false;
    }
    return true;
  }
};

const EncerramentoService = {
  async getAll(filters = {}) {
    const sb = getSupabase();
    if (!sb) return [];
    let query = sb.from('encerramentos_ficais').select('*').order('data_evento', { ascending: false });
    if (filters.ficai_numero) query = query.eq('ficai_numero', filters.ficai_numero);
    const { data, error } = await query;
    if (error) {
      console.warn('Erro ao carregar encerramentos do Supabase:', error);
      return [];
    }
    return data || [];
  },

  async insert(record) {
    const sb = getSupabase();
    if (!sb) return null;
    const payload = {
      id: record.id || ('enc-' + Date.now()),
      ficai_numero: record.ficai_numero || record.numero || record.ficai,
      aluno_nome: record.aluno_nome || record.aluno || record.student || 'Aluno',
      escola_nome: record.escola_nome || record.escola || '',
      turma: record.turma || '',
      tipo_acao: record.tipo_acao || record.tipo || 'Encerramento',
      motivo: record.motivo || '',
      justificativa: record.justificativa || '',
      responsavel: record.responsavel || '',
      data_evento: record.data_evento || record.date || new Date().toISOString()
    };
    const { data, error } = await sb.from('encerramentos_ficais').insert([payload]).select();
    if (error) {
      console.warn('Erro ao salvar encerramento no Supabase:', error);
      return null;
    }
    return data?.[0];
  }
};

const UserService = {
  async getAll() {
    const sb = getSupabase();
    if (!sb) return [];
    const { data, error } = await sb.from('usuarios').select('*').order('usuario');
    if (error) {
      console.warn('Erro ao carregar usuarios do Supabase:', error);
      return [];
    }
    return data || [];
  },

  async saveUser(user) {
    const sb = getSupabase();
    if (!sb) return null;

    const email = (user.email || '').trim().toLowerCase();
    const nome = user.usuario || user.nome || 'Usuário';
    const login = user.login || user.usuario || email.split('@')[0];
    const nivel = user.nivel || 'Usuário';
    const cargo = user.cargo || '';
    const funcao = user.funcao || user.cargo || '';
    const unidade = user.unidade || '';
    const senha = user.senha || '';
    const ativo = user.ativo !== false;

    // 1. Tenta executar via RPC seguro (atualiza auth.users + public.usuarios)
    try {
      const { data, error } = await sb.rpc('ficai_upsert_auth_user', {
        p_id: user.id || null,
        p_nome: nome,
        p_email: email,
        p_login: login,
        p_nivel: nivel,
        p_cargo: cargo,
        p_funcao: funcao,
        p_unidade: unidade,
        p_senha: senha,
        p_ativo: ativo
      });

      if (!error && data) {
        return data;
      }
      if (error) {
        console.info('RPC ficai_upsert_auth_user indisponível ou erro, usando fallback direto na tabela:', error.message);
      }
    } catch (_rpcErr) {
      console.warn('Exceção ao chamar RPC ficai_upsert_auth_user:', _rpcErr);
    }

    // 2. Fallback direto na tabela public.usuarios
    const payload = {
      id: user.id || ('usr-' + Date.now()),
      usuario: nome,
      email: email,
      login: login,
      nivel: nivel,
      cargo: cargo,
      funcao: funcao,
      unidade: unidade,
      ativo: ativo,
      updated_at: new Date().toISOString()
    };

    const { data: dbUser, error: dbErr } = await sb.from('usuarios').upsert([payload]).select();
    if (dbErr) {
      console.warn('Erro ao persistir usuario na tabela public.usuarios:', dbErr);
    }

    // 3. Se foi fornecida senha e e-mail e temos Supabase Auth signUp fallback
    if (email && senha && senha.length >= 6) {
      try {
        await sb.auth.signUp({
          email,
          password: senha,
          options: {
            data: {
              name: nome,
              role: nivel,
              cargo: cargo,
              unidade: unidade
            }
          }
        });
      } catch (_authErr) {
        console.warn('Tentativa de signUp auth fallback:', _authErr);
      }
    }

    return dbUser?.[0] || payload;
  },

  async deleteUser(id) {
    const sb = getSupabase();
    if (!sb || !id) return false;
    const { error } = await sb.from('usuarios').delete().eq('id', id);
    if (error) {
      console.warn('Erro ao excluir usuario no Supabase:', error);
      return false;
    }
    return true;
  }
};

// Exporta para escopo global se em navegador
if (typeof window !== 'undefined') {
  window.SupabaseConfig = { SUPABASE_URL, SUPABASE_ANON_KEY, STORAGE_BUCKET_DOCS };
  window.getSupabase = getSupabase;
  window.StudentService = StudentService;
  window.DocumentService = DocumentService;
  window.FicaiService = FicaiService;
  window.MarcadorService = MarcadorService;
  window.EscolaService = EscolaService;
  window.CancelamentoService = CancelamentoService;
  window.LogService = LogService;
  window.EncerramentoService = EncerramentoService;
  window.UserService = UserService;
}

