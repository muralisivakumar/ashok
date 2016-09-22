package com.example.amulya.listviewcheckboxapp;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ListView;
import android.widget.TextView;

import java.util.ArrayList;

public class MainActivity1 extends AppCompatActivity implements  ListView1Interface{
    Model model;
    ArrayList<Model> fruitsList;
    ListAdapter1 adapter;
    ListView listfruits;
    Button submit;
    TextView text;
    CheckBox checkBox;
    int listcount;
    int countlist=0;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main1);
        String fruits[] = {"Apple", "Banana", "Black Berry", "Beetroot",
                "Custard apple", "Dates", "Elderberry", "Endive", "Fennel",
                "Garlic", "Grapes", "Gauvas", "Olive", "Orange", "Papaya Raw",
                "Pear", "Pineapple", "Pomogranate", "Sapodilla", "Watermelon"};

        listfruits = (ListView) findViewById(R.id.list);

        text = (TextView) findViewById(R.id.text1);


        fruitsList = new ArrayList<Model>();

        for (int i = 0; i < fruits.length; i++) {
            model = new Model();

            model.setName(fruits[i]);

            fruitsList.add(model);
        }

        adapter = new ListAdapter1(MainActivity1.this, fruitsList);

        listfruits.setAdapter(adapter);

        adapter.notifyDataSetChanged();
    }

    @Override
    public void checkedListStates(int position, boolean val) {
        System.out.println("checked item position is..."+position+"...."+val);
        if(val)
        {
            fruitsList.get(position).setSelected(true);
            adapter.notifyDataSetChanged();
        }
        else
        {
            fruitsList.get(position).setSelected(false);
            adapter.notifyDataSetChanged();
        }

    }
}
