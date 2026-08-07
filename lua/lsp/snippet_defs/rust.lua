M = {}
M.filetype = "rust"
M.snippets = {
	{
		kind = "Snippet",
		word = "fnr",
		abbr = "fnr",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = "fn $1($2) -> Result<$3> {\n\t$0\n}",
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "tfn",
		abbr = "tfn",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = "#[test]\nfn $1($2) {\n\t$0\n}",
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "tfnr",
		abbr = "tfnr",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = "#[test]\nfn $1($2) -> Result<$3> {\n\t$0\n}",
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "tmod",
		abbr = "tmod",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = "#[cfg(test)]\nmod test {\n\t$0\n}",
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "gamesys",
		abbr = "gamesys",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = [[#[derive(Clone, Default, Debug, PartialEq, Serialize, Deserialize)]
pub struct ${1:MySystem} {
	$0
}

#[core_proc::game_system]
impl GameSystem for $1 {
	fn init(&self, world: World) -> World {
		world
	}

	fn update(&self, world: World, session_store: SessionStore, _dt: f32) -> (World, SessionStore) {
		(world, session_store)
	}
}]],
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "uictrl",
		abbr = "uictrl",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = [[#[derive(Clone, Debug, Default, Serialize, Deserialize)]
struct ${1:MyPanelController} {
	$0
}

#[typetag::serde]
impl UIController for $1 {
	fn ident(&self) -> &'static str {
		"$1"
	}

	fn on_enter_view(&mut self, _ui_stack: &mut dyn UIStack) -> Vec<message_core::Message> {
		vec![]
	}

	fn update(
		&mut self,
		events: &[DataBindingEvent],
		_ui_stack: &mut dyn UIStack,
		_dt: f32,
	) -> Vec<DataBindingEvent> {
		let mut out_events = vec![];

		for event in events {
			if event.producer == "${2:my_button}" && event.ty == DataBindingEventType::ButtonPress {
				// React to UI events here.
			}
		}

		out_events
	}
}

fn ${3:create_my_panel}() -> Box<dyn UIController> {
	Box::<$1>::default()
}

inventory::submit! { RegistrationData { creation_fn: $3 } }]],
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "gcomp",
		abbr = "gcomp",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = [[#[derive(GlobalComponent, Debug, Default, Clone, Serialize, Deserialize, PartialEq)]
pub struct ${1:MyGlobalComponent} {
	$0
}]],
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "ecomp",
		abbr = "ecomp",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = [[#[derive(EntityComponent, Debug, Default, Clone, Serialize, Deserialize, PartialEq)]
pub struct ${1:MyEntityComponent} {
	$0
}]],
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "scomp",
		abbr = "scomp",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = [[#[derive(SessionComponent, Debug, Default, Clone, Serialize, Deserialize, PartialEq)]
pub struct ${1:MySessionComponent} {
	$0
}]],
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
	{
		kind = "Snippet",
		word = "msgcb",
		abbr = "msgcb",
		user_data = {
			nvim = {
				lsp = {
					completion_item = {
						textEdit = {
							newText = [[pub fn ${1:on_message}(state: Box<dyn Any>, message: Message) -> (Box<dyn Any>, Vec<Message>) {
	let Some(${2:_message}) = get_message::<${3:MyMessage}>(message) else {
		return (state, vec![]);
	};

	let mut state = get_state::<${4:MyPluginState}>(state).expect("Expected a type of State");

	$0

	(state, vec![])
}]],
						},
						insertTextFormat = 2,
					},
				},
			},
		},
	},
}

return M
