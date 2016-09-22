package com.example.amulya.listviewcheckboxapp;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.TextView;

import java.util.ArrayList;

/**
 * Created by Amulya on 8/30/2016.
 */
public class ListAdapter1 extends BaseAdapter {
    Context context;
    ArrayList<Model> list;
    ListView1Interface listInterface;

    public ListAdapter1(Context c, ArrayList<Model> l) {
        this.context = c;
        this.list = l;
        this.listInterface = (ListView1Interface)c;
  }

    @Override
    public int getCount() {
        // TODO Auto-generated method stub
        return list.size();
    }

    @Override
    public Object getItem(int position) {
        // TODO Auto-generated method stub
        return list.get(position);
    }

    @Override
    public long getItemId(int position) {
        // TODO Auto-generated method stub
        return list.hashCode();
    }

    @Override
    public View getView(final int position, View convertView, ViewGroup parent) {
        View v;
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        if (convertView == null) {
            v = inflater.inflate(R.layout.list_grid, null);

        } else {
            v = convertView;
        }
        TextView fruitText = (TextView) v.findViewById(R.id.text1);

        CheckBox checkbox = (CheckBox) v.findViewById(R.id.check);

        final Model m = list.get(position);
        fruitText.setText(m.getName());
        if(m.isSelected())
        {
            checkbox.setChecked(true);
        }
        else
        {
            checkbox.setChecked(false);
        }

        checkbox.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                boolean checked = ((CheckBox)v).isChecked();
                for(int i =0;i<list.size();i++) {
                    if (checked) {
                        listInterface.checkedListStates(position, true);
                      } else {
                        listInterface.checkedListStates(position, false);
                    }
                }
            }
        });

        return v;

    }
}