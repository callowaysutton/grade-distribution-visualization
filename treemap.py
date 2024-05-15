import plotly.graph_objects as go

# Define the initial treemap data
initial_labels = ["A", "B", "C", "D", "E", "F"]
initial_parents = ["", "", "", "", "", ""]
initial_values = [10, 20, 30, 40, 50, 60]

# Define the final treemap data
final_labels = ["A", "B", "C", "D", "E", "F"]
final_parents = ["", "", "", "", "", ""]
final_values = [60, 50, 40, 30, 20, 10]

# Create the figure
fig = go.Figure()

# Add the initial frame
fig.add_trace(go.Treemap(
    labels=initial_labels,
    parents=initial_parents,
    values=initial_values,
    name="Initial"
))

# Add the final frame
fig.frames = [
    go.Frame(
        data=[go.Treemap(
            labels=final_labels,
            parents=final_parents,
            values=final_values,
            name="Final"
        )],
        name="Final"
    )
]

# Update the layout with animation settings for automatic playback
fig.update_layout(
    updatemenus=[
        {
            "buttons": [
                {
                    "args": [None, {"frame": {"duration": 1000, "redraw": True}, "fromcurrent": True, "mode": "immediate"}],
                    "label": "Play",
                    "method": "animate"
                }
            ],
            "direction": "left",
            "showactive": False,
            "type": "buttons",
            "x": 0.1,
            "xanchor": "left",
            "y": 0,
            "yanchor": "top"
        }
    ],
    sliders=[
        {
            "active": 0,
            "yanchor": "top",
            "xanchor": "left",
            "currentvalue": {
                "font": {"size": 20},
                "prefix": "State:",
                "visible": True,
                "xanchor": "right"
            },
            "transition": {"duration": 300, "easing": "cubic-in-out"},
            "pad": {"b": 10, "t": 50},
            "len": 0.9,
            "x": 0.1,
            "y": 0,
            "steps": [
                {
                    "args": [[f.name], {"frame": {"duration": 300, "redraw": True}, "mode": "immediate", "transition": {"duration": 300}}],
                    "label": f.name,
                    "method": "animate"
                } for f in fig.frames
            ]
        }
    ],
    # Add the loop and autoplay settings
    autosize=True,
    height=700,
    width=1000,
    paper_bgcolor='rgba(0,0,0,0)',
    plot_bgcolor='rgba(0,0,0,0)',
    showlegend=False,
    margin=dict(l=0, r=0, t=0, b=0),
)

fig.show(config={'displayModeBar': False})

# Adding the automatic play and loop configuration
fig.update_layout(
    updatemenus=[
        dict(
            type="buttons",
            showactive=False,
            buttons=[
                dict(
                    label="Play",
                    method="animate",
                    args=[None, dict(frame=dict(duration=1000, redraw=True), fromcurrent=True, mode='immediate', transition=dict(duration=0))]
                )
            ]
        )
    ]
)

fig.update_layout(
    sliders=[{
        "steps": [
            {
                "args": [
                    [f.name],
                    {
                        "frame": {"duration": 1000, "redraw": True},
                        "mode": "immediate",
                        "transition": {"duration": 0}
                    }
                ],
                "label": f.name,
                "method": "animate"
            } for f in fig.frames
        ],
        "transition": {"duration": 0},
        "x": 0.1,
        "xanchor": "left",
        "y": 0,
        "yanchor": "top"
    }]
)

fig.update_layout(transition={'duration': 0})

# Configure the animation settings to play automatically and loop infinitely
fig.update_layout(
    updatemenus=[
        {
            "type": "buttons",
            "showactive": False,
            "buttons": [
                {
                    "label": "Play",
                    "method": "animate",
                    "args": [None, {"frame": {"duration": 1000, "redraw": True}, "fromcurrent": True, "mode": "immediate", "transition": {"duration": 0}}],
                }
            ]
        }
    ]
)

# Display the figure
fig.show()

# Adding the script to automatically play the animation
fig.write_html("animated_treemap.html", auto_open=True, include_plotlyjs='cdn')

with open("animated_treemap.html", "r") as file:
    content = file.read()

# Add JavaScript to start the animation on load
content = content.replace("</body>", """
<script>
    document.addEventListener('DOMContentLoaded', function(){
        Plotly.animate('graph', null, {
            frame: {duration: 1000, redraw: true},
            mode: 'immediate'
        });
    });
</script>
</body>
""")

with open("animated_treemap.html", "w") as file:
    file.write(content)
